extends Node
## CastleAi.gd
##
## Autoload singleton that plays your custom 9x9 strategy game. Add this
## file as an AutoLoad singleton named "CastleAi" (Project Settings >
## AutoLoad) - your board script already expects that name via lines
## like:
##   if GameManager.Bots_difficulty == true: CastleAi.time_budget_ms = 8000
##   else: CastleAi.time_budget_ms = 1000
##
## Piece values (matches your current board.gd comments exactly):
##   1 paysan, 2 soldat, 3 archer, 4 cannonier, 5 cavalier, 6 roi, 7 wall
##   The roi (6) now moves exactly like a soldat (2), per your
##   get_moves() dispatch.
##
## IMPORTANT - `white` convention:
## `white == true` means the side to move owns the NEGATIVE-numbered
## pieces, and `white == false` means the side to move owns the
## POSITIVE pieces - matches is_enemy()/_input() in your board script,
## so pass your `white` variable straight through, no flipping needed.
##
## --- Two ways to call it ---
##
## 1) Synchronous (drop-in, no board.gd changes needed):
##
##   var move = CastleAi.get_best_move(board, white)
##   if move:
##       var result = CastleAi.apply_move(board, move.from, move.to, white)
##       if result.winner != null: end(result.winner)
##       white = !white
##       display_board()
##
## 2) Asynchronous / lag-friendly (background thread, same total think
##    time, but the main thread isn't frozen for it):
##
##   var move = await CastleAi.get_best_move_async(board, white)
##   (the `await` is required - it's a coroutine)
## ---------------------------

const BOARD_SIZE := 9

# How long (in ms) the AI is allowed to think before it must return a move.
var time_budget_ms: int = 1000

# Piece values keyed by abs(board value). Used only for evaluation.
const VALUES := {
	1: 100,   # paysan
	2: 320,   # soldat
	3: 330,   # archer
	4: 500,   # cannonier (long-range, stationary capture)
	5: 300,   # cavalier (adjacent/double jump-capture)
	6: 20000, # roi (king) - losing it ends the game
}

## How much one square of extra mobility is worth, in the same units as
## VALUES above. Kept small on purpose: mobility only breaks ties or
## nudges between moves of similar material value - it should never be
## worth more than giving up even the cheapest piece (paysan = 100).
## Positive-side mobility counts up, negative-side mobility counts down,
## so this rewards both "give my own pieces more squares" and "leave the
## opponent's pieces with fewer squares" (i.e. trapping them) - without
## ever preferring that over a material gain or against a material loss.
const MOBILITY_WEIGHT := 1.5

var _deadline_ms: int = 0
var _aborted: bool = false
var _nodes: int = 0
var _search_thread: Thread = null


# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Returns the best move found within time_budget_ms as
## { "from": Vector2, "to": Vector2 }, or {} if the side to move has no
## legal moves at all. Blocks the calling thread for up to
## time_budget_ms - use get_best_move_async() if that freeze is a
## problem for you.
func get_best_move(board: Array, white: bool) -> Dictionary:
	_deadline_ms = Time.get_ticks_msec() + time_budget_ms
	_aborted = false
	_nodes = 0

	var moves := get_all_moves(board, white)
	if moves.is_empty():
		return {}

	_order_moves(board, moves)
	var best_move: Dictionary = moves[0]

	# Iterative deepening: keep the best move from the last fully
	# completed depth, refine it further while time allows.
	var depth := 1
	while Time.get_ticks_msec() < _deadline_ms and depth <= 6:
		var alpha := -INF
		var beta := INF
		var current_best: Dictionary = {}
		var current_best_score: float = -INF
		var aborted_mid_depth := false

		for move in moves:
			var record := _make_move(board, move.from, move.to, white)
			var score := -_negamax(board, depth - 1, -beta, -alpha, !white)
			_unmake_move(board, record)

			if _aborted:
				aborted_mid_depth = true
				break

			if score > current_best_score:
				current_best_score = score
				current_best = move
			if score > alpha:
				alpha = score

		if not aborted_mid_depth and not current_best.is_empty():
			best_move = current_best
			# Try the best move first next iteration (cheap move ordering).
			moves.erase(best_move)
			moves.push_front(best_move)
			# Found a forced king capture - no point searching deeper.
			if current_best_score >= VALUES[6] * 0.5:
				break
		elif aborted_mid_depth and depth == 1 and not current_best.is_empty():
			# Ran out of time before finishing even depth 1 - still take
			# whatever partial result we have over the arbitrary fallback.
			best_move = current_best

		depth += 1

	return best_move


## Same as get_best_move(), but runs the search on a background thread
## and only touches the main thread to check "done yet?" once a frame,
## so the game keeps rendering while the bot thinks. Must be called with
## `await`. Uses a private copy of `board`.
func get_best_move_async(board: Array, white: bool) -> Dictionary:
	if _search_thread != null and _search_thread.is_alive():
		push_warning("CastleAi: get_best_move_async() called while a search is already running - ignoring.")
		return {}

	var board_copy := _copy_board(board)
	_search_thread = Thread.new()
	_search_thread.start(func():
		return get_best_move(board_copy, white)
	)

	while _search_thread.is_alive():
		await get_tree().process_frame

	var result: Dictionary = _search_thread.wait_to_finish()
	_search_thread = null
	return result


## Applies a move to `board` in place, matching set_move() in your board
## script:
##  - paysans and soldats (and the roi, which moves like a soldat)
##    overwrite the target square directly. A paysan reaching the far
##    three rows promotes to a soldat.
##  - cavaliers (value 5) jump: over one adjacent piece to land 2 squares
##    away (capturing it only if it was an enemy), or - in a straight
##    orthogonal line only - over two consecutive enemies to land 3
##    squares away, capturing both. Walls can never be jumped over.
##  - archers and cannoniers remove an enemy at range without moving
##    onto it.
##  - walls just sit there to be jumped over (by other pieces) by their
##    own color.
## Returns { "winner": null | bool }. `winner` is null if the game isn't
## over; otherwise it's exactly what you'd pass to your end().
func apply_move(board: Array, from: Vector2, to: Vector2, white: bool) -> Dictionary:
	var record := _make_move(board, from, to, white)
	return {"winner": record.winner}


## Generates every pseudo-legal move for the side to move (per your
## board script's `white` convention). Returns an Array of
## { "from": Vector2, "to": Vector2 }.
func get_all_moves(board: Array, white: bool) -> Array:
	var moves := []
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece = board[x][y]
			if piece == 0 or abs(piece) == 7:
				continue
			if not _is_own(piece, white):
				continue

			var pos := Vector2(x, y)
			for dest in _get_moves_for(board, pos, white):
				moves.append({"from": pos, "to": dest})
	return moves


# ---------------------------------------------------------------------------
# SEARCH (negamax + alpha-beta + iterative deepening + make/unmake)
# ---------------------------------------------------------------------------

func _negamax(board: Array, depth: int, alpha: float, beta: float, white: bool) -> float:
	_nodes += 1
	if _nodes % 512 == 0 and Time.get_ticks_msec() >= _deadline_ms:
		_aborted = true
		return 0.0

	# Cheap check at every node: only scans for the two kings, no
	# mobility generation, so decisive lines are pruned fast.
	var kings := _king_status(board)
	if not kings.positive_alive:
		return _perspective_score(-VALUES[6], white)
	if not kings.negative_alive:
		return _perspective_score(VALUES[6], white)

	if depth <= 0:
		# Full evaluation (material + center + mobility) only happens
		# at the leaves, since mobility means generating every move for
		# both sides - too expensive to redo at every internal node.
		return _perspective_score(_leaf_eval(board), white)

	var moves := get_all_moves(board, white)
	if moves.is_empty():
		return -9999.0 # no legal moves - treat as a bad position

	_order_moves(board, moves)

	var best := -INF
	for move in moves:
		var record := _make_move(board, move.from, move.to, white)
		var score := -_negamax(board, depth - 1, -beta, -alpha, !white)
		_unmake_move(board, record)

		if _aborted:
			return 0.0

		if score > best:
			best = score
		if best > alpha:
			alpha = best
		if alpha >= beta:
			break # alpha-beta cutoff

	return best


func _order_moves(board: Array, moves: Array) -> void:
	# Cheap move ordering: check removals/captures first, biggest first,
	# so alpha-beta prunes more.
	moves.sort_custom(func(a, b):
		return _move_gain(board, a) > _move_gain(board, b)
	)


func _move_gain(board: Array, move: Dictionary) -> int:
	var from: Vector2 = move.from
	var to: Vector2 = move.to
	var piece = board[from.x][from.y]
	var kind := _cavalier_jump_kind(piece, from, to)

	if kind == "single":
		var mid = from + (to - from) / 2
		return VALUES.get(abs(board[mid.x][mid.y]), 0)
	elif kind == "double":
		var unit = _unit_dir(to - from)
		var mid1 = from + unit
		var mid2 = from + unit * 2
		return VALUES.get(abs(board[mid1.x][mid1.y]), 0) + VALUES.get(abs(board[mid2.x][mid2.y]), 0)

	return VALUES.get(abs(board[to.x][to.y]), 0)


# ---------------------------------------------------------------------------
# EVALUATION
# ---------------------------------------------------------------------------

## Cheap scan: just whether each king is still on the board. No
## mobility, no material sum - this is what runs at every search node so
## a king capture is detected (and pruned) fast.
func _king_status(board: Array) -> Dictionary:
	var positive_alive := false
	var negative_alive := false
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece = board[x][y]
			if piece == 6:
				positive_alive = true
			elif piece == -6:
				negative_alive = true
		if positive_alive and negative_alive:
			break
	return {"positive_alive": positive_alive, "negative_alive": negative_alive}


## Material + centralisation, always from the POSITIVE-piece side's
## point of view (positive = good for the positive pieces), independent
## of whose turn it is. Assumes both kings are already known to be alive.
func _material_and_center(board: Array) -> float:
	var score := 0.0
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece = board[x][y]
			if piece == 0 or abs(piece) == 7:
				continue
			var value = VALUES.get(abs(piece), 0)

			# Small centralisation bonus so the bot doesn't just sit still.
			var center_bonus = 4.0 - (abs(x - 4) + abs(y - 4)) * 0.5

			if piece > 0:
				score += value + center_bonus
			else:
				score -= value + center_bonus
	return score


## Full leaf evaluation: material + center, plus a mobility term that
## rewards the AI's own pieces having more squares to go to and the
## opponent's having fewer (i.e. trapping them). Only called at leaves -
## see _negamax().
func _leaf_eval(board: Array) -> float:
	var score := _material_and_center(board)

	var positive_mobility := get_all_moves(board, false).size()
	var negative_mobility := get_all_moves(board, true).size()
	score += float(positive_mobility - negative_mobility) * MOBILITY_WEIGHT

	return score


## Converts a raw (positive-side-relative) score into "how good is this
## for whoever's turn it is", using your board script's `white`
## convention (white == true -> mover owns the negative pieces).
func _perspective_score(raw: float, white: bool) -> float:
	return -raw if white else raw


# ---------------------------------------------------------------------------
# MOVE GENERATION - mirrors get_paysan_moves() / get_soldat_moves() / etc.
# from your board script, parameterised by position + `white` instead of
# the instance's selected_pieces/white fields.
# ---------------------------------------------------------------------------

func _get_moves_for(board: Array, pos: Vector2, white: bool) -> Array:
	match abs(board[pos.x][pos.y]):
		1: return _paysan_moves(board, pos, white)
		2: return _soldat_moves(board, pos, white)
		3: return _archer_moves(board, pos, white)
		4: return _canonnier_moves(board, pos, white)
		5: return _cavalier_moves(board, pos, white)
		6: return _soldat_moves(board, pos, white) # roi moves exactly like a soldat now
	return []


func _paysan_moves(board: Array, pos: Vector2, white: bool) -> Array:
	var moves := []
	var directions
	if not white:
		directions = [Vector2(0,1),Vector2(0,-1),Vector2(-1,0)]
	else:
		directions = [Vector2(0,1),Vector2(0,-1),Vector2(1,0)]
	for d in directions:
		var p = pos + d
		if _is_valid(p) and _is_empty(board, p, white):
			moves.append(p)

	directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1)]
	for d in directions:
		var p = pos + d
		if _is_valid(p) and _is_enemy(board, p, white):
			moves.append(p)
	return moves


func _soldat_moves(board: Array, pos: Vector2, white: bool) -> Array:
	var moves := []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),
					   Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	for d in directions:
		var p = pos + d
		if not _is_valid(p):
			continue
		if _is_empty(board, p, white):
			moves.append(p)
		elif _is_enemy(board, p, white):
			moves.append(p)
		elif _is_own_wall(board, p, white) and _is_valid(p + d) and _is_empty(board, p + d, white):
			moves.append(p + d)
	return moves


## Archer (value 3): short move/push like the others, plus a true
## knight-shaped ranged capture (8 L-shaped directions) that removes an
## enemy without moving onto it.
func _archer_moves(board: Array, pos: Vector2, white: bool) -> Array:
	var moves := []
	var directions = [Vector2(0,1),Vector2(0,-1),Vector2(-1,0),Vector2(1,0)]
	for d in directions:
		var p = pos + d
		if not _is_valid(p):
			continue
		if _is_empty(board, p, white):
			moves.append(p)
		elif _is_own_wall(board, p, white) and _is_valid(p + d) and _is_empty(board, p + d, white):
			moves.append(p + d)

	directions = [Vector2(2,-1),Vector2(2,1),Vector2(-1,2),Vector2(1,2),
				  Vector2(-2,-1),Vector2(-2,1),Vector2(-1,-2),Vector2(1,-2)]
	for d in directions:
		var p = pos + d
		if _is_valid(p) and _is_enemy(board, p, white) and abs(board[p.x][p.y]) != 7:
			moves.append(p)
	return moves


## Cannonier (value 4): short move/push like the others, plus a 3-square
## straight shot that removes an enemy at range without moving onto it.
func _canonnier_moves(board: Array, pos: Vector2, white: bool) -> Array:
	var moves := []
	var directions
	if white:
		directions = [Vector2(0,-1),Vector2(0,1),Vector2(1,0)]
	else:
		directions = [Vector2(0,-1),Vector2(0,1),Vector2(-1,0)]

	for d in directions:
		var p = pos + d
		if not _is_valid(p):
			continue
		if _is_empty(board, p, white):
			moves.append(p)
		elif _is_own_wall(board, p, white) and _is_valid(p + d) and _is_empty(board, p + d, white):
			moves.append(p + d)

	if not white:
		directions = [Vector2(-3,-1),Vector2(-3,0),Vector2(-3,1)]
	else:
		directions = [Vector2(3,-1),Vector2(3,0),Vector2(3,1)]

	for d in directions:
		var p = pos + d
		if _is_valid(p) and _is_enemy(board, p, white) and abs(board[p.x][p.y]) != 7:
			moves.append(p)
	return moves


## Cavalier (value 5): normal one-step move to any of the 8 adjacent
## squares, or:
##  - a jump over one adjacent piece (any of the 8 directions) to land 2
##    squares away, capturing that piece only if it's an enemy (jumping
##    a friendly piece is allowed but captures nothing);
##  - a jump over two consecutive enemies in a straight ORTHOGONAL line
##    only (not diagonal) to land 3 squares away, capturing both.
## Walls can never be jumped over, in either case - see the note in the
## chat reply about why.
func _cavalier_moves(board: Array, pos: Vector2, white: bool) -> Array:
	var moves := []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),
					   Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	for d in directions:
		var p = pos + d
		if _is_valid(p) and _is_empty(board, p, white):
			moves.append(p)

	for d in directions:
		var p = pos + d
		if _is_valid(p) and _is_valid(p + d):
			if not _is_empty(board, p, white) and abs(board[p.x][p.y]) != 7 and _is_empty(board, p + d, white):
				moves.append(p + d)

	var ortho = [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	for d in ortho:
		var p1 = pos + d
		var p2 = pos + d * 2
		var p3 = pos + d * 3
		if _is_valid(p1) and _is_valid(p2) and _is_valid(p3):
			if _is_enemy(board, p1, white) and abs(board[p1.x][p1.y]) != 7 \
			and _is_enemy(board, p2, white) and abs(board[p2.x][p2.y]) != 7 \
			and _is_empty(board, p3, white):
				moves.append(p3)
	return moves


# ---------------------------------------------------------------------------
# HELPERS - these mirror is_valid_position()/is_empty()/is_enemy() from
# your board script exactly, using its `white` convention.
# ---------------------------------------------------------------------------

func _is_valid(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE


## Matches your board script's is_empty(): a truly empty square, OR the
## enemy king's square (which counts as "empty" for move-generation
## purposes, letting quiet-move patterns capture the king too).
func _is_empty(board: Array, pos: Vector2, white: bool) -> bool:
	var v = board[pos.x][pos.y]
	if v == 0:
		return true
	if (v == 6 and white) or (v == -6 and not white):
		return true
	return false


## True if the piece at `pos` belongs to the side to move (white==true
## means that side owns the negative-numbered pieces).
func _is_own(piece: int, white: bool) -> bool:
	return (white and piece < 0) or (not white and piece > 0)


## True if the piece at `pos` belongs to the opponent - matches
## is_enemy() in your board script exactly.
func _is_enemy(board: Array, pos: Vector2, white: bool) -> bool:
	var v = board[pos.x][pos.y]
	return (white and v > 0) or (not white and v < 0)


## True if the wall at `pos` is the SAME color as the mover, i.e. the one
## your soldat/archer/cannonier move code lets you jump through.
func _is_own_wall(board: Array, pos: Vector2, white: bool) -> bool:
	var v = board[pos.x][pos.y]
	return (v == 7 and not white) or (v == -7 and white)


func _unit_dir(delta: Vector2) -> Vector2:
	return Vector2(sign(delta.x), sign(delta.y))


## Classifies a cavalier move as "single" (2-square jump over one piece),
## "double" (3-square jump over two enemies, orthogonal only) or "" (not
## a jump - either a normal step or not a cavalier at all).
func _cavalier_jump_kind(piece: int, from: Vector2, to: Vector2) -> String:
	if abs(piece) != 5:
		return ""
	var delta = to - from
	if delta == Vector2.ZERO:
		return ""
	var ax = abs(int(delta.x))
	var ay = abs(int(delta.y))
	if not (ax == ay or ax == 0 or ay == 0):
		return "" # not a straight line in one of the 8 directions
	var reach = max(ax, ay)
	if reach == 2:
		return "single"
	if reach == 3:
		return "double"
	return ""


func _copy_board(board: Array) -> Array:
	var copy := []
	copy.resize(board.size())
	for i in board.size():
		copy[i] = board[i].duplicate()
	return copy


# ---------------------------------------------------------------------------
# MAKE / UNMAKE - mutate `board` in place and return everything needed to
# put it back exactly as it was. This is what lets the search avoid
# cloning the whole board at every node.
# ---------------------------------------------------------------------------

func _make_move(board: Array, from: Vector2, to: Vector2, white: bool) -> Dictionary:
	var piece = board[from.x][from.y]
	var kind := _cavalier_jump_kind(piece, from, to)
	var winner = null

	if kind == "single":
		var mid = from + (to - from) / 2
		var mid_value = board[mid.x][mid.y]

		if white and mid_value == 6: winner = false
		elif not white and mid_value == -6: winner = true

		board[to.x][to.y] = piece
		board[from.x][from.y] = 0
		var mid_cleared = false
		if (mid_value > 0 and white) or (mid_value < 0 and not white):
			board[mid.x][mid.y] = 0
			mid_cleared = true

		return {
			"kind": "jump1", "from": from, "to": to, "mid": mid,
			"piece": piece, "mid_value": mid_value, "mid_cleared": mid_cleared,
			"winner": winner,
		}

	if kind == "double":
		var unit = _unit_dir(to - from)
		var mid1 = from + unit
		var mid2 = from + unit * 2
		var mid1_value = board[mid1.x][mid1.y]
		var mid2_value = board[mid2.x][mid2.y]

		if (white and (mid1_value == 6 or mid2_value == 6)):
			winner = false
		elif (not white and (mid1_value == -6 or mid2_value == -6)):
			winner = true

		board[to.x][to.y] = piece
		board[from.x][from.y] = 0
		var mid1_cleared = false
		var mid2_cleared = false
		if (mid1_value > 0 and white) or (mid1_value < 0 and not white):
			board[mid1.x][mid1.y] = 0
			mid1_cleared = true
		if (mid2_value > 0 and white) or (mid2_value < 0 and not white):
			board[mid2.x][mid2.y] = 0
			mid2_cleared = true

		return {
			"kind": "jump2", "from": from, "to": to, "mid1": mid1, "mid2": mid2,
			"piece": piece,
			"mid1_value": mid1_value, "mid1_cleared": mid1_cleared,
			"mid2_value": mid2_value, "mid2_cleared": mid2_cleared,
			"winner": winner,
		}

	var target = board[to.x][to.y]
	if white and target == 6: winner = false
	elif not white and target == -6: winner = true

	if target == 0 or abs(piece) == 2 or abs(piece) == 1:
		var promoted = abs(piece) == 1 and ((to.x < 2 and not white) or (to.x > 6 and white))
		board[to.x][to.y] = 2 if promoted else piece
		board[from.x][from.y] = 0
		return {
			"kind": "move", "from": from, "to": to,
			"piece": piece, "target_before": target,
			"winner": winner,
		}
	else:
		var cleared = false
		if (target > 0 and white) or (target < 0 and not white):
			board[to.x][to.y] = 0
			cleared = true
		return {
			"kind": "stationary", "to": to,
			"target_before": target, "cleared": cleared,
			"winner": winner,
		}


func _unmake_move(board: Array, record: Dictionary) -> void:
	match record.kind:
		"jump1":
			board[record.from.x][record.from.y] = record.piece
			board[record.to.x][record.to.y] = 0
			board[record.mid.x][record.mid.y] = record.mid_value
		"jump2":
			board[record.from.x][record.from.y] = record.piece
			board[record.to.x][record.to.y] = 0
			board[record.mid1.x][record.mid1.y] = record.mid1_value
			board[record.mid2.x][record.mid2.y] = record.mid2_value
		"move":
			board[record.from.x][record.from.y] = record.piece
			board[record.to.x][record.to.y] = record.target_before
		"stationary":
			if record.cleared:
				board[record.to.x][record.to.y] = record.target_before
