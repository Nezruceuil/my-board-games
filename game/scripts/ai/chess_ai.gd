extends Node
class_name ChessAI
## Alpha-beta minimax AI for the board in chess.gd. Meant to be used as an
## autoload singleton named "Ai" (matches how chess.gd calls it: Ai.xxx).
##
## IMPORTANT — turn-flag convention:
## In chess.gd, the bool `white` is true when it is BLACK's turn to move
## (it's used to gate which color of piece you're allowed to click).
## This script keeps that EXACT same convention so you can pass chess.gd's
## `white` variable straight in without converting it — it's just called
## `black_turn` here to make the meaning obvious.
##
## This ruleset has no check/checkmate — the game ends when a king is
## captured — so no legal-move filtering for "leaves your king in check"
## is needed. That's what keeps this search simple and fast.

const VALUES := {1: 100, 2: 320, 3: 330, 4: 500, 5: 900, 6: 20000}
const MATE_SCORE := 1000000.0
const REPETITION_DRAW_SCORE := 0.0

## Time budget per move, in milliseconds. Set this from chess.gd
## (e.g. Ai.time_budget_ms = 1000). Iterative deepening searches depth
## 1, 2, 3... and keeps the best move from the last depth it fully
## finished within this budget, so turns never take longer than this
## no matter how sharp the position is.
var time_budget_ms: int = 800

## Hard ceiling so a very quiet/simple position (e.g. king + pawn endgame)
## can't search forever even if it technically has time left.
var max_depth_cap: int = 8

var _deadline_msec: int = 0


# ---------------------------------------------------------------------------
# PUBLIC ENTRY POINT
# ---------------------------------------------------------------------------

## board            : the live 8x8 Array (Array of Arrays) from chess.gd
## black_turn       : pass chess.gd's `white` variable directly
## en_passant       : pass chess.gd's `en_passant` variable directly (Vector2 or null)
## castle_rights    : Dictionary with keys white_king, black_king, white_rook_left,
##                    white_rook_right, black_rook_left, black_rook_right —
##                    pass chess.gd's variables of the same names in a dict.
## position_history : Dictionary of position-key -> occurrence count, built up
##                    over the real game so far. Pass {} to disable
##                    repetition-avoidance.
##
## Returns { "from": Vector2, "to": Vector2 } or {} if no legal move exists.
func find_best_move(board: Array, black_turn: bool, en_passant, castle_rights: Dictionary, position_history: Dictionary = {}) -> Dictionary:
	_deadline_msec = Time.get_ticks_msec() + time_budget_ms
	var best_overall := {}
	var depth := 1

	while depth <= max_depth_cap:
		var result := _search_root(board, black_turn, en_passant, castle_rights, position_history, depth)
		if not result.move.is_empty() and not result.timed_out:
			best_overall = result.move
		if result.timed_out or Time.get_ticks_msec() >= _deadline_msec:
			break
		depth += 1

	# Fallback: if even depth 1 timed out (shouldn't normally happen), just
	# take whatever move it got to, rather than returning nothing.
	if best_overall.is_empty():
		var fallback := _get_all_moves(board, black_turn, en_passant, castle_rights)
		if not fallback.is_empty():
			best_overall = fallback[0]

	return best_overall


func _search_root(board: Array, black_turn: bool, en_passant, castle_rights: Dictionary, position_history: Dictionary, depth: int) -> Dictionary:
	var moves := _get_all_moves(board, black_turn, en_passant, castle_rights)
	if moves.is_empty():
		return {"move": {}, "timed_out": false}

	moves.sort_custom(func(a, b): return _mvv_lva(board, a) > _mvv_lva(board, b))

	var best_move := {}
	var alpha := -INF
	var beta := INF
	var timed_out := false

	if !black_turn:
		var best_score := -INF
		for m in moves:
			if Time.get_ticks_msec() >= _deadline_msec:
				timed_out = true
				break
			var b2 := _clone_board(board)
			var c2 := castle_rights.duplicate()
			var ep2 = _apply_move(b2, m, black_turn, en_passant, c2)
			var key2 := compute_position_key(b2, !black_turn, c2, ep2)
			var hist2 := position_history.duplicate()
			hist2[key2] = position_history.get(key2, 0) + 1
			var score := _minimax(b2, depth - 1, alpha, beta, !black_turn, ep2, c2, hist2, key2)
			if score > best_score:
				best_score = score
				best_move = m
			alpha = max(alpha, score)
	else:
		var best_score := INF
		for m in moves:
			if Time.get_ticks_msec() >= _deadline_msec:
				timed_out = true
				break
			var b2 := _clone_board(board)
			var c2 := castle_rights.duplicate()
			var ep2 = _apply_move(b2, m, black_turn, en_passant, c2)
			var key2 := compute_position_key(b2, !black_turn, c2, ep2)
			var hist2 := position_history.duplicate()
			hist2[key2] = position_history.get(key2, 0) + 1
			var score := _minimax(b2, depth - 1, alpha, beta, !black_turn, ep2, c2, hist2, key2)
			if score < best_score:
				best_score = score
				best_move = m
			beta = min(beta, score)

	return {"move": best_move, "timed_out": timed_out}


# ---------------------------------------------------------------------------
# MINIMAX + ALPHA-BETA
# ---------------------------------------------------------------------------

func _minimax(board: Array, depth: int, alpha: float, beta: float, black_turn: bool, en_passant, castle_rights: Dictionary, position_history: Dictionary, current_key: String) -> float:
	var kings := _find_kings(board)
	if not kings.white:
		return -MATE_SCORE - depth  # white lost its king
	if not kings.black:
		return MATE_SCORE + depth   # black lost its king

	if position_history.get(current_key, 0) >= 3:
		return REPETITION_DRAW_SCORE  # this position has now occurred 3 times

	if Time.get_ticks_msec() >= _deadline_msec:
		return _evaluate(board, en_passant, castle_rights)

	if depth <= 0:
		return _evaluate(board, en_passant, castle_rights)

	var moves := _get_all_moves(board, black_turn, en_passant, castle_rights)
	if moves.is_empty():
		return _evaluate(board, en_passant, castle_rights)

	moves.sort_custom(func(a, b): return _mvv_lva(board, a) > _mvv_lva(board, b))

	if !black_turn:
		var value := -INF
		for m in moves:
			var b2 := _clone_board(board)
			var c2 := castle_rights.duplicate()
			var ep2 = _apply_move(b2, m, black_turn, en_passant, c2)
			var key2 := compute_position_key(b2, !black_turn, c2, ep2)
			var hist2 := position_history.duplicate()
			hist2[key2] = position_history.get(key2, 0) + 1
			value = max(value, _minimax(b2, depth - 1, alpha, beta, !black_turn, ep2, c2, hist2, key2))
			alpha = max(alpha, value)
			if alpha >= beta:
				break
		return value
	else:
		var value := INF
		for m in moves:
			var b2 := _clone_board(board)
			var c2 := castle_rights.duplicate()
			var ep2 = _apply_move(b2, m, black_turn, en_passant, c2)
			var key2 := compute_position_key(b2, !black_turn, c2, ep2)
			var hist2 := position_history.duplicate()
			hist2[key2] = position_history.get(key2, 0) + 1
			value = min(value, _minimax(b2, depth - 1, alpha, beta, !black_turn, ep2, c2, hist2, key2))
			beta = min(beta, value)
			if alpha >= beta:
				break
		return value


func _find_kings(board: Array) -> Dictionary:
	var found := {"white": false, "black": false}
	for row in board:
		for v in row:
			if v == 6: found.white = true
			elif v == -6: found.black = true
	return found


# ---------------------------------------------------------------------------
# REPETITION TRACKING
# ---------------------------------------------------------------------------

## Builds a string key identifying a position for repetition tracking —
## board layout + whose turn + castle rights + en passant target, since all
## of those affect what can legally happen next (same idea as the real
## chess repetition rule).
func compute_position_key(board: Array, black_turn: bool, castle_rights: Dictionary, en_passant) -> String:
	var parts := PackedStringArray()
	for row in board:
		for v in row:
			parts.append(str(v))
	var ep_str := "none"
	if en_passant != null:
		ep_str = str(en_passant.x) + "_" + str(en_passant.y)
	var castle_str := "%s%s%s%s%s%s" % [
		int(castle_rights.white_king), int(castle_rights.black_king),
		int(castle_rights.white_rook_left), int(castle_rights.white_rook_right),
		int(castle_rights.black_rook_left), int(castle_rights.black_rook_right)
	]
	return ",".join(parts) + "|" + ("b" if black_turn else "w") + "|" + castle_str + "|" + ep_str


# ---------------------------------------------------------------------------
# EVALUATION
# ---------------------------------------------------------------------------

## MOBILITY_WEIGHT rewards generally having more options than the opponent.
## RESTRICTION_WEIGHT kicks in hard once a side is down to very few legal
## moves -- this is what makes the AI actively steer toward positions where
## the opponent is nearly out of safe replies (a "trap"), since in this
## ruleset a boxed-in king can be forced onto a square you capture next turn.
const MOBILITY_WEIGHT := 4.0
const RESTRICTION_WEIGHT := 15.0
const RESTRICTION_THRESHOLD := 2  # "nearly out of moves" cutoff

## CENTER_WEIGHT is the base reward for occupying/controlling central
## squares. QUEEN_KING_CENTER_SCALE cuts that reward way down for the
## queen and king specifically -- otherwise walking the queen to the
## middle looks just as good as developing a knight there, which is
## exactly the bad habit we don't want the AI to pick up.
const CENTER_WEIGHT := 3.0
const QUEEN_KING_CENTER_SCALE := 0.15

## Penalize bringing the queen out while most minor pieces (knights/
## bishops) are still sitting undeveloped on the back rank -- the
## classic "develop minors before the queen" opening principle. Only
## applies while >=2 minors are still home, so it naturally stops
## mattering once the opening's over.
const EARLY_QUEEN_PENALTY := 50.0
const UNDEVELOPED_MINOR_THRESHOLD := 2

## Endgame pawn pushing: once most of the pieces are off the board,
## advancing pawns toward promotion matters a lot -- reward it, with
## an extra kick once a pawn is one square from queening.
const ENDGAME_PIECE_THRESHOLD := 6  # total non-pawn, non-king pieces left, both sides
const PAWN_ADVANCE_WEIGHT := 4.0    # per rank advanced, endgame only
const NEAR_PROMOTION_BONUS := 25.0  # extra, one square from queening

## Castling / king safety.
const LOST_CASTLE_PENALTY := 30.0        # moved the king without ever castling
const LOST_ROOK_RIGHT_PENALTY := 8.0     # moved a rook before castling, closing an option
const CASTLED_KING_SAFETY_BONUS := 40.0  # actually tucked the king away via castling
const PAWN_SHIELD_BONUS := 8.0           # per friendly pawn directly shielding the king

func _evaluate(board: Array, en_passant, castle_rights: Dictionary) -> float:
	var score := 0.0
	var white_minors_home := 0
	var black_minors_home := 0
	var white_queen_home := false
	var black_queen_home := false
	var white_king_pos = null
	var black_king_pos = null
	var non_pawn_king_pieces := 0
	var white_pawn_rows := []
	var black_pawn_rows := []

	for r in range(8):
		for c in range(8):
			var v = board[r][c]
			if v == 0: continue
			var val = VALUES[abs(v)]
			score += val * sign(v)

			var centre_bonus = (3 - abs(3.5 - r)) + (3 - abs(3.5 - c))
			var weight = CENTER_WEIGHT
			if abs(v) == 5 or abs(v) == 6:
				weight *= QUEEN_KING_CENTER_SCALE
			score += centre_bonus * weight * sign(v)

			if v == 2 or v == 3:
				if r == 7: white_minors_home += 1
				non_pawn_king_pieces += 1
			elif v == -2 or v == -3:
				if r == 0: black_minors_home += 1
				non_pawn_king_pieces += 1
			elif v == 4 or v == -4:
				non_pawn_king_pieces += 1
			elif v == 5:
				non_pawn_king_pieces += 1
				if r == 7 and c == 3: white_queen_home = true
			elif v == -5:
				non_pawn_king_pieces += 1
				if r == 0 and c == 3: black_queen_home = true
			elif v == 6:
				white_king_pos = Vector2(r, c)
			elif v == -6:
				black_king_pos = Vector2(r, c)
			elif v == 1:
				white_pawn_rows.append(r)
			elif v == -1:
				black_pawn_rows.append(r)

	if not white_queen_home and white_minors_home >= UNDEVELOPED_MINOR_THRESHOLD:
		score -= EARLY_QUEEN_PENALTY
	if not black_queen_home and black_minors_home >= UNDEVELOPED_MINOR_THRESHOLD:
		score += EARLY_QUEEN_PENALTY

	# Endgame pawn advancement — only kicks in once material has thinned out.
	if non_pawn_king_pieces <= ENDGAME_PIECE_THRESHOLD:
		for r in white_pawn_rows:
			var advanced = 6 - r  # white pawns start on row 6, promote on row 0
			score += advanced * PAWN_ADVANCE_WEIGHT
			if r == 1:  # one square from queening
				score += NEAR_PROMOTION_BONUS
		for r in black_pawn_rows:
			var advanced = r - 1  # black pawns start on row 1, promote on row 7
			score -= advanced * PAWN_ADVANCE_WEIGHT
			if r == 6:  # one square from queening
				score -= NEAR_PROMOTION_BONUS

	# Castling / king safety.
	var white_castled = white_king_pos != null and white_king_pos.x == 7 and (white_king_pos.y == 2 or white_king_pos.y == 6)
	var black_castled = black_king_pos != null and black_king_pos.x == 0 and (black_king_pos.y == 2 or black_king_pos.y == 6)

	if castle_rights.white_king and not white_castled:
		score -= LOST_CASTLE_PENALTY  # moved the king and never got to castle
	elif white_castled:
		score += CASTLED_KING_SAFETY_BONUS
	if not white_castled:
		if castle_rights.white_rook_left: score -= LOST_ROOK_RIGHT_PENALTY
		if castle_rights.white_rook_right: score -= LOST_ROOK_RIGHT_PENALTY

	if castle_rights.black_king and not black_castled:
		score += LOST_CASTLE_PENALTY
	elif black_castled:
		score -= CASTLED_KING_SAFETY_BONUS
	if not black_castled:
		if castle_rights.black_rook_left: score += LOST_ROOK_RIGHT_PENALTY
		if castle_rights.black_rook_right: score += LOST_ROOK_RIGHT_PENALTY

	if white_king_pos != null:
		score += _pawn_shield_bonus(board, white_king_pos, true)
	if black_king_pos != null:
		score -= _pawn_shield_bonus(board, black_king_pos, false)

	var white_moves = _get_all_moves(board, false, en_passant, castle_rights).size()
	var black_moves = _get_all_moves(board, true, en_passant, castle_rights).size()

	score += (white_moves - black_moves) * MOBILITY_WEIGHT

	if black_moves <= RESTRICTION_THRESHOLD:
		score += (RESTRICTION_THRESHOLD + 1 - black_moves) * RESTRICTION_WEIGHT
	if white_moves <= RESTRICTION_THRESHOLD:
		score -= (RESTRICTION_THRESHOLD + 1 - white_moves) * RESTRICTION_WEIGHT

	return score


## Counts friendly pawns on the row directly in front of the king (toward
## the enemy side), within one column either way -- a simple pawn-shield
## check, e.g. f/g/h pawns for a kingside-castled king in normal chess.
func _pawn_shield_bonus(board: Array, king_pos: Vector2, is_white: bool) -> float:
	var bonus := 0.0
	var front_row = king_pos.x - 1 if is_white else king_pos.x + 1
	if front_row < 0 or front_row > 7:
		return 0.0
	for dc in [-1, 0, 1]:
		var col = king_pos.y + dc
		if col < 0 or col > 7: continue
		var v = board[front_row][col]
		if is_white and v == 1: bonus += PAWN_SHIELD_BONUS
		elif not is_white and v == -1: bonus += PAWN_SHIELD_BONUS
	return bonus


func _mvv_lva(board: Array, m: Dictionary) -> int:
	var target = board[m.to.x][m.to.y]
	if target == 0:
		return 0
	var attacker = board[m.from.x][m.from.y]
	return VALUES[abs(target)] - int(VALUES[abs(attacker)] / 10.0)


# ---------------------------------------------------------------------------
# MOVE GENERATION — mirrors chess.gd's get_*_moves(), but pure/parameterised
# so it can run on a scratch board during search without touching game state.
# ---------------------------------------------------------------------------

func _get_all_moves(board: Array, black_turn: bool, en_passant, castle_rights: Dictionary) -> Array:
	var moves := []
	for r in range(8):
		for c in range(8):
			var v = board[r][c]
			if v == 0: continue
			var is_black_piece = v < 0
			if is_black_piece != black_turn: continue
			var pos := Vector2(r, c)
			var piece_moves := []
			match abs(v):
				1: piece_moves = _pawn_moves(board, pos, black_turn, en_passant)
				2: piece_moves = _knight_moves(board, pos, black_turn)
				3: piece_moves = _bishop_moves(board, pos, black_turn)
				4: piece_moves = _rook_moves(board, pos, black_turn)
				5: piece_moves = _queen_moves(board, pos, black_turn)
				6: piece_moves = _king_moves(board, pos, black_turn, castle_rights)
			for to in piece_moves:
				moves.append({"from": pos, "to": to})
	return moves


func _valid(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8

func _empty(board: Array, pos: Vector2) -> bool:
	return board[pos.x][pos.y] == 0

func _enemy(board: Array, pos: Vector2, black_turn: bool) -> bool:
	return board[pos.x][pos.y] > 0 if black_turn else board[pos.x][pos.y] < 0


func _sliding_moves(board: Array, from: Vector2, black_turn: bool, directions: Array) -> Array:
	var out := []
	for d in directions:
		var pos = from + d
		while _valid(pos):
			if _empty(board, pos):
				out.append(pos)
			elif _enemy(board, pos, black_turn):
				out.append(pos)
				break
			else:
				break
			pos += d
	return out

func _rook_moves(board, from, black_turn) -> Array:
	return _sliding_moves(board, from, black_turn, [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)])

func _bishop_moves(board, from, black_turn) -> Array:
	return _sliding_moves(board, from, black_turn, [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1)])

func _queen_moves(board, from, black_turn) -> Array:
	return _sliding_moves(board, from, black_turn, [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),
		Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)])

func _knight_moves(board, from, black_turn) -> Array:
	var out := []
	var dirs = [Vector2(2,1),Vector2(2,-1),Vector2(1,2),Vector2(-1,2),
				Vector2(-2,1),Vector2(-2,-1),Vector2(1,-2),Vector2(-1,-2)]
	for d in dirs:
		var pos = from + d
		if _valid(pos):
			if _empty(board, pos) or _enemy(board, pos, black_turn):
				out.append(pos)
	return out

func _king_moves(board, from, black_turn, castle: Dictionary) -> Array:
	var out := []
	var dirs = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),
				Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	for d in dirs:
		var pos = from + d
		if _valid(pos):
			if _empty(board, pos) or _enemy(board, pos, black_turn):
				out.append(pos)

	# Castling — mirrors chess.gd's get_king_moves(), including the fixed
	# rook-presence check (a rook must actually still be on the corner
	# square, not just "the moved-flag happens to be false").
	if black_turn and not castle.black_king:
		if not castle.black_rook_left and _empty(board, Vector2(0,1)) and _empty(board, Vector2(0,2)) and _empty(board, Vector2(0,3)) and board[0][0] == -4:
			out.append(Vector2(0,2))
		if not castle.black_rook_right and _empty(board, Vector2(0,5)) and _empty(board, Vector2(0,6)) and board[0][7] == -4:
			out.append(Vector2(0,6))
	elif not black_turn and not castle.white_king:
		if not castle.white_rook_left and _empty(board, Vector2(7,1)) and _empty(board, Vector2(7,2)) and _empty(board, Vector2(7,3)) and board[7][0] == 4:
			out.append(Vector2(7,2))
		if not castle.white_rook_right and _empty(board, Vector2(7,5)) and _empty(board, Vector2(7,6)) and board[7][7] == 4:
			out.append(Vector2(7,6))
	return out

func _pawn_moves(board, from, black_turn, en_passant) -> Array:
	var out := []
	var direction = Vector2(1,0) if black_turn else Vector2(-1,0)
	var is_first_move = (black_turn and from.x == 1) or (!black_turn and from.x == 6)

	if en_passant != null and ((black_turn and from.x == 4) or (!black_turn and from.x == 3)) and abs(en_passant.y - from.y) == 1:
		out.append(en_passant + direction)

	var pos = from + direction
	if _valid(pos) and _empty(board, pos): out.append(pos)

	pos = from + Vector2(direction.x, 1)
	if _valid(pos) and _enemy(board, pos, black_turn): out.append(pos)
	pos = from + Vector2(direction.x, -1)
	if _valid(pos) and _enemy(board, pos, black_turn): out.append(pos)

	pos = from + direction * 2
	if is_first_move and _valid(pos) and _empty(board, pos) and _empty(board, from + direction):
		out.append(pos)

	return out


# ---------------------------------------------------------------------------
# APPLYING A MOVE TO A CLONED BOARD (search-only — the real game still moves
# pieces through chess.gd's own set_move(), see integration notes)
# ---------------------------------------------------------------------------

func _clone_board(board: Array) -> Array:
	var out := []
	for row in board:
		out.append(row.duplicate())
	return out


## Mutates `board` and `castle` in place. Returns the new en_passant value.
func _apply_move(board: Array, m: Dictionary, black_turn: bool, en_passant, castle: Dictionary):
	var from: Vector2 = m.from
	var to: Vector2 = m.to
	var piece = board[from.x][from.y]
	var new_en_passant = null

	match piece:
		-1:
			if to.x == 3 and from.x == 1:
				new_en_passant = to
			elif en_passant != null and en_passant.y == to.y and from.y != to.y and en_passant.x == from.x:
				board[en_passant.x][en_passant.y] = 0
		1:
			if to.x == 4 and from.x == 6:
				new_en_passant = to
			elif en_passant != null and en_passant.y == to.y and from.y != to.y and en_passant.x == from.x:
				board[en_passant.x][en_passant.y] = 0
		4:
			# FIXED: white rooks start on row 7, not row 0.
			if from.x == 7 and from.y == 0: castle.white_rook_left = true
			if from.x == 7 and from.y == 7: castle.white_rook_right = true
		-4:
			# FIXED: black rooks start on row 0, not row 7.
			if from.x == 0 and from.y == 0: castle.black_rook_left = true
			if from.x == 0 and from.y == 7: castle.black_rook_right = true
		-6:
			if from.x == 0 and from.y == 4:
				castle.black_king = true
				if to.y == 2:
					castle.black_rook_left = true
					castle.black_rook_right = true
					board[0][0] = 0
					board[0][3] = -4
				elif to.y == 6:
					castle.black_rook_left = true
					castle.black_rook_right = true
					board[0][7] = 0
					board[0][5] = -4
		6:
			if from.x == 7 and from.y == 4:
				castle.white_king = true
				if to.y == 2:
					castle.white_rook_left = true
					castle.white_rook_right = true
					board[7][0] = 0
					board[7][3] = 4
				elif to.y == 6:
					castle.white_rook_left = true
					castle.white_rook_right = true
					board[7][7] = 0
					board[7][5] = 4

	board[to.x][to.y] = piece
	board[from.x][from.y] = 0

	# Auto-queen promotion (search/eval only — the real game still shows its
	# own promotion UI when the AI's move is actually executed).
	if piece == -1 and to.x == 7:
		board[to.x][to.y] = -5
	elif piece == 1 and to.x == 0:
		board[to.x][to.y] = 5

	return new_en_passant
