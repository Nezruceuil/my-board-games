extends Control

const BOARD_SIZE = 9
const CELL_WIDTH = 60

const SHOGI_TEXTURE = preload("uid://b78711aw7wu3k")
const CHESS_TEXTURE = preload("uid://y84bw3qsbxxw")


const MOVES = preload("uid://dgujov8w87o3n")


const BISHOP = preload("uid://b2sgabekov7w4")
const GOLD_GENERAL = preload("uid://c6eyvcvgqjo0y")
const KING = preload("uid://cxmoyvx4uxu4")
const KNIGHT = preload("uid://bh6l48k567nyg")
const PAWN = preload("uid://b83e52ri2j66i")
const ROOK = preload("uid://dau3kwc8ovh6h")
const SILVER_GENERAL = preload("uid://gm0bk3ij7off")
const SPEAR = preload("uid://bag042olsqbsc")
const PROMOTED_BISHOP = preload("uid://cfe8s2hoswtiq")
const PROMOTED_ROOK = preload("uid://dfaf2ccfcvylf")


const BLACK_QUEEN = preload("uid://dvqdryfjf2fg0")
const WHITE_QUEEN = preload("uid://jmtskg520hkl")
const WHITE_PIZZA = preload("uid://dc63laq3wjrd8")
const BLACK_PIZZA = preload("uid://c45jtfg4qx7wt")

@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dots



# Vars
# 0 = empty
# 1 = PAWN
# 2 = KNIGHT
# 3 = BISHOP
# 4 = ROOK
# 5 = PROMOTED ROOK
# 6 = KING
# 7 = SILVER GENERAL
# 8 = GOLD GENERAL
# 9 = SPEAR
# 10 = PROMOTED BISHOP


var position_history: Dictionary = {}

var board : Array
var white : bool = false
var state : bool = false
var moves = []
var selected_pieces : Vector2

var promotion_square = null

var white_king = false
var black_king = false
var white_rook_left = false
var white_rook_right = false
var black_rook_left = false
var black_rook_right = false

var en_passant = null

var rng = RandomNumberGenerator.new()

var drawing = []
var arrows = []

var time = Vector2(60,60)

func _process(delta: float) -> void:
	if not GameManager.Q2 == 2 and not (time.x == 0 or time.y == 0):
		if white:
			time.x -= delta
			$CanvasLayer/Timer.text = "TIME LEFT: " + str(round(time.x * 100)/100)
		else:
			time.y -= delta
			$CanvasLayer/Timer.text = "TIME LEFT: " + str(round(time.y * 100)/100)
		
		if time.x < 0:
			time.x = 0
			time.y = 0
			end(true)
		elif time.y < 0:
			time.x = 0
			time.y = 0
			end(false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.Bots_difficulty == true: ChessAi.time_budget_ms = 8000
	else: ChessAi.time_budget_ms = 1000
	
	if GameManager.Q2 == 1: time = Vector2(300,300)
	elif GameManager.Q2 == 3: time = Vector2(1200,1200)
	else: $CanvasLayer/Timer.visible = false
	
	if not GameManager.Q1 == 1:
		board.append([-9, -2, -7, -8, -6, -8, -7, -2, -9])
		board.append([0, -4, 0, 0, 0, 0, 0, -3, 0])
		board.append([-1, -1, -1, -1, -1, -1, -1, -1, -1])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([1, 1, 1, 1, 1, 1, 1, 1, 1])
		board.append([0, 3, 0, 0, 0, 0, 0, 4, 0])
		board.append([9, 2, 7, 8, 6, 8, 7, 2, 9])
	else:
		board.append([-9, -2, -7, -8, -6, -8, -7, 0, -9])
		board.append([0, 0, 0, 0, 0, -4, 0, -3, 0])
		board.append([-1, -1, 0, -1, -1, 0, 0, -1, -1])
		board.append([0, 0, -1, 0, 0, 0, -1, 0, 0])
		board.append([0, 0, 0, 0, 0, -2, 0, 0, 0])
		board.append([0, 0, 0, 0, 1, 0, 1, 1, 0])
		board.append([1, 1, 1, 1, 0, 8, 2, 0, 1])
		board.append([0, 3, 0, 0, 0, 4, 0, 0, 0])
		board.append([9, 2, 7, 8, 6, 0, 7, 0, 9])
	
	display_board()
	
	
	var white_buttons = get_tree().get_nodes_in_group("white_pieces")
	var black_buttons = get_tree().get_nodes_in_group("black_pieces")
	
	for button in white_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
	for button in black_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
	


func display_board():
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = SHOGI_TEXTURE.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) - 270, -i * CELL_WIDTH - (CELL_WIDTH / 2) + 270)
			if board[abs(i-8)][j] < 0: holder.rotation_degrees = 180
			
			if GameManager.Q1 == 3:
				holder.texture = MOVES
				holder.modulate = Color(1.0, 1.0, 1.0, 0.0)
			match abs(board[abs(i-8)][j]):
				0 : holder.texture = null
				10 : holder.texture = PROMOTED_BISHOP
				9 : holder.texture = SPEAR
				8 : holder.texture = GOLD_GENERAL
				7 : holder.texture = SILVER_GENERAL
				6 : holder.texture = KING
				5 : holder.texture = PROMOTED_ROOK
				4 : holder.texture = ROOK
				3 : holder.texture = BISHOP
				2 : holder.texture = KNIGHT
				1 : holder.texture = PAWN
	
	if white:
		$CanvasLayer/Label.text = "P2 turn"
		$Camera2D.rotation_degrees = 180
	else:
		$CanvasLayer/Label.text = "P1 turn"
		$Camera2D.rotation_degrees = 0


func _input(event: InputEvent) -> void:
	if event.is_action("Delete"):
		drawing = []
		arrows = []
		for child in $move.get_children():
			child.queue_free()
		for child in $arrows.get_children():
			child.queue_free()
	elif event is InputEventMouseButton && event.pressed && promotion_square == null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_out()
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 330,0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 330,0) / CELL_WIDTH) - 1

			if !state and (white && board[var2][var1] < 0) or !state and (!white && board[var2][var1] > 0):
				selected_pieces = Vector2(var2, var1)
				show_options()
				state = true
			elif state == true: set_move(var2,var1)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 330, 0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 330, 0) / CELL_WIDTH) - 1
			await get_tree().create_timer(0.2).timeout
			var _var1 = (snapped(get_global_mouse_position().x + 330, 0) / CELL_WIDTH) - 1
			var _var2 = (snapped(get_global_mouse_position().y + 330, 0) / CELL_WIDTH) - 1

			if Vector2(var2, var1) == Vector2(_var2, _var1):
				show_drawing(var2, var1)
			else:
				_var1 = -1
				while not (_var1 == (snapped(get_global_mouse_position().x + 330, 0) / CELL_WIDTH) - 1 \
					and _var2 == (snapped(get_global_mouse_position().y + 330, 0) / CELL_WIDTH) - 1):
					_var1 = (snapped(get_global_mouse_position().x + 330, 0) / CELL_WIDTH) - 1
					_var2 = (snapped(get_global_mouse_position().y + 330, 0) / CELL_WIDTH) - 1
					await get_tree().create_timer(0.25).timeout
				_var1 = (snapped(get_global_mouse_position().x + 330, 0) / CELL_WIDTH) - 1
				_var2 = (snapped(get_global_mouse_position().y + 330, 0) / CELL_WIDTH) - 1

				if is_valid_position(Vector2(_var2, _var1)):
					if Vector2(var2, var1) == Vector2(_var2, _var1):
						show_drawing(var2, var1)
					else:
						var dx = _var1 - var1
						var dy = _var2 - var2
						var length = sqrt(pow(dx, 2) + pow(dy, 2))
						var dir = atan2(dy, dx)

						show_arrows(var2, var1, dir, length)

func show_arrows(x,y,dir,length):
	if arrows.has(Vector4(x,y,dir,length)):
		var has = false
		for i in arrows.size():
			if has == false:
				if arrows[i] == Vector4(x,y,dir,length):
					arrows.remove_at(i)
					has = true
	else:
		arrows.insert(0,Vector4(x,y,dir,length))
	
	
	for child in $arrows.get_children():
		child.queue_free()
	
	const ARROWS_2 = preload("uid://ccoticpruvb84")
	const ARROWS_1 = preload("uid://d2seayohxq2ln")
	
	for i in arrows.size():
			var child = CHESS_TEXTURE.instantiate()
			$arrows.add_child(child)
			child.texture = ARROWS_1
			child.scale = Vector2(3.5*arrows[i].w,3.5)
			child.modulate = GameManager.color
			child.global_position = Vector2(arrows[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(arrows[i].x-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)
			child.rotation = arrows[i].z
			child.move_local_x(abs(arrows[i].w - 9))
			
			var child2 = CHESS_TEXTURE.instantiate()
			$arrows.add_child(child2)
			child2.texture = ARROWS_2
			child2.modulate = GameManager.color
			child2.rotation = arrows[i].z
			child2.global_position = Vector2(arrows[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(arrows[i].x-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)
			child2.move_local_x(arrows[i].w * CELL_WIDTH + 16)

func show_drawing(x,y):
	if drawing.has(Vector2(x,y)):
		var has = false
		for i in drawing.size():
			if has == false:
				if drawing[i].x == x and  drawing[i].y == y:
					drawing.remove_at(i)
					has = true
	else:
		drawing.insert(0,Vector2(x,y))
	
	for child in $move.get_children():
		child.queue_free()
	
	for i in drawing.size():
			var child = CHESS_TEXTURE.instantiate()
			$move.add_child(child)
			child.texture = MOVES
			child.modulate = GameManager.color
			child.global_position = Vector2(drawing[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(drawing[i].x-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)


func is_mouse_out():
	if get_global_mouse_position().x < 270 and get_global_mouse_position().x > -270 and get_global_mouse_position().y > -270 and get_global_mouse_position(). y < 270 : return true
	return false

func show_options():
	moves = get_moves()
	if moves == []:
		state = false
	else:
		show_dots()

func show_dots():
	delete_dots()
	for i in moves:
		var holder = CHESS_TEXTURE.instantiate()
		dots.add_child(holder)
		holder.texture = MOVES
		holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(i.x-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var2,var1):
	
	delete_dots()
	for i in moves:
		if i.x == var2 and i.y == var1:
			if white and board[var2][var1] == 6: end(false)
			elif !white and board[var2][var1] == -6: end(true)
			
			match board[selected_pieces.x][selected_pieces.y]:
				-1:
					if i.x > 5: promote(selected_pieces,8)
				1:
					if i.x < 3: promote(selected_pieces,8)
				-2:
					if i.x > 5: promote(selected_pieces,8)
				2:
					if i.x < 3: promote(selected_pieces,8)
				-3:
					if i.x > 5: promote(selected_pieces,10)
				3:
					if i.x < 3: promote(selected_pieces,10)
				-4:
					if i.x > 5: promote(selected_pieces,5)
				4:
					if i.x < 3: promote(selected_pieces,5)
				-7:
					if i.x > 5: promote(selected_pieces,8)
				7:
					if i.x < 3: promote(selected_pieces,8)
				-9:
					if i.x > 5: promote(selected_pieces,8)
				9:
					if i.x < 3: promote(selected_pieces,8)
			
			
			board[var2][var1] = board[selected_pieces.x][selected_pieces.y]
			board[selected_pieces.x][selected_pieces.y] = 0
			
			drawing = []
			arrows = []
			for child in $move.get_children():
				child.queue_free()
			for child in $arrows.get_children():
				child.queue_free()
			
			var _1 = CHESS_TEXTURE.instantiate()
			$move.add_child(_1)
			_1.texture = MOVES
			_1.modulate = Color(0.898, 0.776, 1.0, 0.588)
			_1.global_position = Vector2(selected_pieces.y * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(selected_pieces.x-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)
			
			var _2 = CHESS_TEXTURE.instantiate()
			$move.add_child(_2)
			_2.texture = MOVES
			_2.modulate = Color(0.776, 0.443, 1.0, 0.588)
			_2.global_position = Vector2(var1 * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(var2-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)
			
			white = !white
			display_board()
			var pos_key = ChessAi.compute_position_key(board, white, {
			"white_king": white_king, "black_king": black_king,
			"white_rook_left": white_rook_left, "white_rook_right": white_rook_right,
			"black_rook_left": black_rook_left, "black_rook_right": black_rook_right,
			}, en_passant)
			position_history[pos_key] = position_history.get(pos_key, 0) + 1
			
			var text = ""
			match abs(board[var2][var1]):
				2: text = "knight "
				3: text = "bishop "
				4: text = "rook "
				5: text = "p-rook "
				6: text = "king "
				7: text = "silver general "
				8: text = "gold general "
				9: text = "spear "
				10: text = "p-bishop"
			match int(var1):
				0: text += "a"
				1: text += "b"
				2: text += "c"
				3: text += "d"
				4: text += "e"
				5: text += "f"
				6: text += "g"
				7: text += "h"
				8: text += "i"
			text += str(round(abs(int(var2)-9)))
			$CanvasLayer/buttons/chat.text += "
			" + text
			
			break
	state = false
	maybe_do_ai_move()


func get_moves():
	var _moves = []
	match abs(board[selected_pieces.x][selected_pieces.y]):
		1: _moves = get_pawn_moves()
		2: _moves = get_knight_moves()
		3: _moves = get_bishop_moves()
		4: _moves = get_rook_moves()
		5:
			_moves = get_rook_moves()
			_moves += get_king_moves(_moves)
		6: _moves = get_king_moves([])
		7: _moves = get_silver_general_moves()
		8: _moves = get_gold_general_moves()
		9: _moves = get_spear_moves()
		10:
			_moves = get_bishop_moves()
			_moves += get_king_moves(_moves)
		
	return _moves


func get_spear_moves():
	var _moves = []
	var directions = []
	
	if white: directions = [Vector2(1,0)]
	else: directions = [Vector2(-1,0)]
	
	var pos = selected_pieces
	pos += directions[0]
	while is_valid_position(pos):
		if is_empty(pos) and is_valid_position(pos): _moves.append(pos)
		elif is_enemy(pos):
			_moves.append(pos)
			break
		else: break
		
		pos += directions[0]
	
	return _moves


func get_silver_general_moves():
	var _moves = []
	var directions = []
	if !white: directions = [Vector2(-1,1),Vector2(-1,0),Vector2(-1,-1), Vector2(1,1),Vector2(1,-1)]
	else:directions = [Vector2(1,1),Vector2(1,0),Vector2(1,-1), Vector2(-1,1),Vector2(-1,-1)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
	
	return _moves

func get_gold_general_moves():
	var _moves = []
	var directions = []
	if !white: directions = [Vector2(-1,1),Vector2(-1,0),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0)]
	else:directions = [Vector2(1,1),Vector2(1,0),Vector2(1,-1),Vector2(0,1),Vector2(0,-1),Vector2(-1,0)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
	
	return _moves

func get_rook_moves():
	var _moves = []
	var directions = [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	for i in directions:
		var pos = selected_pieces
		pos += i
		while is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
				break
			else: break
			
			pos += i
	
	return _moves

func get_bishop_moves():
	var _moves = []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1)]
	
	for i in directions:
		var pos = selected_pieces
		pos += i
		while is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
				break
			else: break
			
			pos += i
	
	return _moves


func get_king_moves(_has):
	var _moves = []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	for i in directions:
		var pos = selected_pieces + i
		if not _has.has(pos):
			if is_valid_position(pos):
				if is_empty(pos): _moves.append(pos)
				elif is_enemy(pos):
					_moves.append(pos)
	
	return _moves

func get_knight_moves():
	var _moves = []
	var directions = []
	
	if white: directions = [Vector2(2,1),Vector2(2,-1)]
	else: directions = [Vector2(-2,1),Vector2(-2,-1)]
	
	for i in directions:
		var pos = selected_pieces
		pos += i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
	
	return _moves

func get_pawn_moves():
	var _moves = []
	var direction
	
	if white: direction = Vector2(1, 0)
	else: direction = Vector2(-1, 0)
	
	var pos = selected_pieces + direction
	if is_empty(pos) or is_enemy(pos): _moves.append(pos)
	
	return _moves


func is_valid_position(pos : Vector2):
	if pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE: return true
	return false
func is_empty(pos: Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false
func is_enemy(pos : Vector2):
	if white and board[pos.x][pos.y] > 0 or !white and board[pos.x][pos.y] < 0 : return true
	return false

func promote(_var: Vector2,piece):
	promotion_square = _var
	
	if white: board[promotion_square.x][promotion_square.y] = -piece
	else: board[promotion_square.x][promotion_square.y] = piece
	promotion_square = null
	display_board()



func end(winner:bool):
	if winner == true:
		$CanvasLayer/win/Label.text = "White/Player1 WIN!"
		$CanvasLayer/win/Sprite2D.texture = KING
		GameManager.PlayerVictory[0] += 1
	else:
		$CanvasLayer/win/Label.text = "Black/Player2 WIN!"
		$CanvasLayer/win/Sprite2D.texture = KING
		GameManager.PlayerVictory[1] += 1
	$CanvasLayer/win.visible = true
	
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://game/menu.tscn")


var equal = Vector2(0,0)

func _on_draw_pressed() -> void:
	if white and equal.x == 0:
		if equal.y == 0:
			$CanvasLayer/buttons/chat.text += "
			" + "black offered a draw"
		equal.x = 1
	elif !white and equal.y == 0:
		if equal.x == 0:
			$CanvasLayer/buttons/chat.text += "
			" + "white offered a draw"
		equal.y = 1
	
	$CanvasLayer/buttons/Label.text = str(int(equal.x + equal.y)) + "/2 draws"
	
	
	if equal.x + equal.y == 2:
		$CanvasLayer/buttons/chat.text += "
			" + "draw accepted!"
		GameManager.PlayerVictory[0] += 0.5
		GameManager.PlayerVictory[1] += 0.5
		await get_tree().create_timer(2).timeout
		get_tree().change_scene_to_file("res://game/menu.tscn")







func maybe_do_ai_move():
	if promotion_square != null: return  # wait for the pending promotion to be resolved first

	await get_tree().create_timer(0.15).timeout

	if GameManager.Bots == 3:
		await get_tree().create_timer(0.2).timeout
		call_deferred("do_ai_turn")
	else:
		if GameManager.Bots == 0: return
		if GameManager.Bots%2 == 0 != white: return
		call_deferred("do_ai_turn")

func do_ai_turn():
	var castle_rights = {
		"white_king": white_king, "black_king": black_king,
		"white_rook_left": white_rook_left, "white_rook_right": white_rook_right,
		"black_rook_left": black_rook_left, "black_rook_right": black_rook_right,
	}
	var best = ChessAi.find_best_move(board, white, en_passant, castle_rights, position_history)
	if best.is_empty():
		return

	selected_pieces = best.from
	moves = get_moves()
	state = true
	set_move(best.to.x, best.to.y)


	if promotion_square != null:
		ai_finish_promotion()

func ai_finish_promotion(piece_num := 5):
	if promotion_square == null: return
	if !white: board[promotion_square.x][promotion_square.y] = -piece_num
	else: board[promotion_square.x][promotion_square.y] = piece_num
	promotion_square = null
	display_board()
