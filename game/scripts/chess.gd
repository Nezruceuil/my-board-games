extends Control

const BOARD_SIZE = 8
const CELL_WIDTH = 60

const CHESS_TEXTURE = preload("uid://y84bw3qsbxxw")

const MOVES = preload("uid://dgujov8w87o3n")

const BLACK_BISHOP = preload("uid://csr8od1k1m7fv")
const BLACK_KING = preload("uid://bxfchep71u5pt")
const BLACK_KNIGHT = preload("uid://c3s5fffhvjx2k")
const BLACK_QUEEN = preload("uid://dvqdryfjf2fg0")
const BLACK_ROOK = preload("uid://jkabjmbygbs6")
const WHITE_BISHOP = preload("uid://drcbuc8pqapuk")
const WHITE_KING = preload("uid://y57qje8eqgen")
const WHITE_KNIGHT = preload("uid://twxk4uwbkubu")
const WHITE_PAWN = preload("uid://yad0fhepxuqm")
const WHITE_QUEEN = preload("uid://jmtskg520hkl")
const WHITE_ROOK = preload("uid://becc2akj8mxvu")
const BLACK_PAWN = preload("uid://cys3ofokiewp6")

@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dots

@onready var white_pieces: Control = $CanvasLayer/White_pieces
@onready var black_pieces: Control = $CanvasLayer/Black_pieces


# Vars
# -6 = black king
# -5 = black queen
# -4 = black rook
# -3 = black bishop
# -2 = black knight
# -1 = black pawn
# 0 = empty
# 6 = white king
# 5 = white queen
# 4 = white rook
# 3 = white bishop
# 2 = white knight
# 1 = white pawn

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
	
	if GameManager.Q2 == 1: time = Vector2(60,60)
	elif GameManager.Q2 == 3: time = Vector2(300,300)
	else: $CanvasLayer/Timer.visible = false
	
	if not GameManager.Q1 == 1:
		board.append([-4, -2, -3 , -5, -6, -3, -2, -4])
		board.append([-1, -1, -1, -1, -1, -1, -1, -1])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([1, 1, 1, 1, 1, 1, 1, 1])
		board.append([4,2, 3, 5, 6, 3, 2, 4])
	else:
		var first_layer = [0,0,0,0,0,0,0,0]
		var has_king = rng.randi_range(0,6)
		for i in 8:
			if i == has_king:
				first_layer[i] = 6
			else:
				first_layer[i] = randi_range(2,5)
		
		board.append([-first_layer[0],-first_layer[1],-first_layer[2],-first_layer[3],-first_layer[4],-first_layer[5],-first_layer[6],-first_layer[7]])
		board.append([-1, -1, -1, -1, -1, -1, -1, -1])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([1, 1, 1, 1, 1, 1, 1, 1])
		board.append([first_layer[0],first_layer[1],first_layer[2],first_layer[3],first_layer[4],first_layer[5],first_layer[6],first_layer[7]])
		
	
	display_board()
	
	
	var white_buttons = get_tree().get_nodes_in_group("white_pieces")
	var black_buttons = get_tree().get_nodes_in_group("black_pieces")
	
	for button in white_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
	for button in black_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
	
	maybe_do_ai_move()


func display_board():
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = CHESS_TEXTURE.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) - 240, -i * CELL_WIDTH - (CELL_WIDTH / 2) + 240)
			if white: holder.rotation_degrees = 180
			
			if GameManager.Q1 == 3:
				holder.texture = MOVES
				holder.modulate = Color(1.0, 1.0, 1.0, 0.0)
			match board[abs(i-7)][j]:
				-6 : holder.texture = BLACK_KING
				-5 : holder.texture = BLACK_QUEEN
				-4 : holder.texture = BLACK_ROOK
				-3 : holder.texture = BLACK_BISHOP
				-2 : holder.texture = BLACK_KNIGHT
				-1 : holder.texture = BLACK_PAWN
				0 : holder.texture = null
				6 : holder.texture = WHITE_KING
				5 : holder.texture = WHITE_QUEEN
				4 : holder.texture = WHITE_ROOK
				3 : holder.texture = WHITE_BISHOP
				2 : holder.texture = WHITE_KNIGHT
				1 : holder.texture = WHITE_PAWN
	
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
			var var1 = (snapped(get_global_mouse_position().x + 300,0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 300,0) / CELL_WIDTH) - 1

			if !state and (white && board[var2][var1] < 0) or !state and (!white && board[var2][var1] > 0):
				selected_pieces = Vector2(var2, var1)
				show_options()
				state = true
			elif state == true: set_move(var2,var1)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 300, 0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 300, 0) / CELL_WIDTH) - 1
			await get_tree().create_timer(0.2).timeout
			var _var1 = (snapped(get_global_mouse_position().x + 300, 0) / CELL_WIDTH) - 1
			var _var2 = (snapped(get_global_mouse_position().y + 300, 0) / CELL_WIDTH) - 1

			if Vector2(var2, var1) == Vector2(_var2, _var1):
				show_drawing(var2, var1)
			else:
				_var1 = -1
				while not (_var1 == (snapped(get_global_mouse_position().x + 300, 0) / CELL_WIDTH) - 1 \
					and _var2 == (snapped(get_global_mouse_position().y + 300, 0) / CELL_WIDTH) - 1):
					_var1 = (snapped(get_global_mouse_position().x + 300, 0) / CELL_WIDTH) - 1
					_var2 = (snapped(get_global_mouse_position().y + 300, 0) / CELL_WIDTH) - 1
					await get_tree().create_timer(0.25).timeout
				_var1 = (snapped(get_global_mouse_position().x + 300, 0) / CELL_WIDTH) - 1
				_var2 = (snapped(get_global_mouse_position().y + 300, 0) / CELL_WIDTH) - 1

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
			child.global_position = Vector2(arrows[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(arrows[i].x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
			child.rotation = arrows[i].z
			child.move_local_x(abs(arrows[i].w - 8))
			
			var child2 = CHESS_TEXTURE.instantiate()
			$arrows.add_child(child2)
			child2.texture = ARROWS_2
			child2.modulate = GameManager.color
			child2.rotation = arrows[i].z
			child2.global_position = Vector2(arrows[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(arrows[i].x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
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
			child.global_position = Vector2(drawing[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(drawing[i].x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)


func is_mouse_out():
	if get_global_mouse_position().x < 240 and get_global_mouse_position().x > -240 and get_global_mouse_position().y > -240 and get_global_mouse_position(). y < 240 : return true
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
		holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(i.x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var2,var1):
	
	var just_now = false
	delete_dots()
	for i in moves:
		if i.x == var2 and i.y == var1:
			if white and board[var2][var1] == 6: end(false)
			elif !white and board[var2][var1] == -6: end(true)
			
			match board[selected_pieces.x][selected_pieces.y]:
				-1:
					if i.x == 7: promote(i)
					if i.x == 3 && selected_pieces.x == 1:
						en_passant = i
						just_now = true
					elif en_passant != null:
						if en_passant.y == i.y && selected_pieces.y != i.y && en_passant.x == selected_pieces.x:
							board[en_passant.x][en_passant.y] = 0
				1:
					if i.x == 0: promote(i)
					if i.x == 4 && selected_pieces.x == 6:
						en_passant = i
						just_now = true
					elif en_passant != null:
						if en_passant.y == i.y && selected_pieces.y != i.y && en_passant.x == selected_pieces.x:
							board[en_passant.x][en_passant.y] = 0
				4:
					if selected_pieces.x == 7 && selected_pieces.y == 0: white_rook_left = true
					if selected_pieces.x == 7 && selected_pieces.y == 7: white_rook_right = true
				-4:
					if selected_pieces.x == 0 && selected_pieces.y == 0: black_rook_left = true
					if selected_pieces.x == 0 && selected_pieces.y == 7: black_rook_right = true
				-6:
					if selected_pieces.x == 0 && selected_pieces.y == 4:
						black_king = true
						if i.y == 2:
							black_rook_left = true
							black_rook_right = true
							board[0][0] = 0
							board[0][3] = -4
						elif i.y == 6:
							black_rook_left = true
							black_rook_right = true
							board[0][7] = 0
							board[0][5] = -4
				6:
					if selected_pieces.x == 7 && selected_pieces.y == 4:
						white_king = true
						if i.y == 2:
							white_rook_left = true
							white_rook_right = true
							board[7][0] = 0
							board[7][3] = 4
						elif i.y == 6:
							white_rook_left = true
							white_rook_right = true
							board[7][7] = 0
							board[7][5] = 4
			
			if !just_now: en_passant = null
			
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
			_1.global_position = Vector2(selected_pieces.y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(selected_pieces.x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
			
			var _2 = CHESS_TEXTURE.instantiate()
			$move.add_child(_2)
			_2.texture = MOVES
			_2.modulate = Color(0.776, 0.443, 1.0, 0.588)
			_2.global_position = Vector2(var1 * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(var2-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
			
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
				5: text = "queen "
				6: text = "king "
				6: text = "pizza "
			match int(var1):
				0: text += "a"
				1: text += "b"
				2: text += "c"
				3: text += "d"
				4: text += "e"
				5: text += "f"
				6: text += "g"
				7: text += "h"
			text += str(round(abs(int(var2)-8)))
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
		5: _moves = get_queen_moves()
		6: _moves = get_king_moves()
		
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

func get_queen_moves():
	var _moves = []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
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

func get_king_moves():
	var _moves = []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
	
	if not GameManager.Q2 == 3:
		if white && !black_king:
			if !black_rook_left && is_empty(Vector2(0, 1)) && is_empty(Vector2(0, 2)) && is_empty(Vector2(0, 3)) && board[0][0] == -4:
				_moves.append(Vector2(0,2))
			if !black_rook_right && is_empty(Vector2(0, 5)) && is_empty(Vector2(0, 6)) && board[0][7] == -4:
				_moves.append(Vector2(0,6))
		elif !white && !white_king:
			if !white_rook_left && is_empty(Vector2(7, 1)) && is_empty(Vector2(7, 2)) && is_empty(Vector2(7, 3)) && board[7][0] == 4:
				_moves.append(Vector2(7,2))
			if !white_rook_right && is_empty(Vector2(7, 5)) && is_empty(Vector2(7, 6)) && board[7][7] == 4:
				_moves.append(Vector2(7,6))
	
	return _moves

func get_knight_moves():
	var _moves = []
	var directions = [Vector2(2,1),Vector2(2,-1),Vector2(1,2),Vector2(-1,2),
						Vector2(-2,1),Vector2(-2,-1),Vector2(1,-2),Vector2(-1,-2)]
	
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
	var is_first_move = false
	
	if white: direction = Vector2(1, 0)
	else: direction = Vector2(-1, 0)
	
	if !white and selected_pieces.x == 6 or white and selected_pieces.x == 1: is_first_move = true
	
	if en_passant != null && (white && selected_pieces.x == 4 or !white && selected_pieces.x == 3) && abs(en_passant.y - selected_pieces.y) == 1:
		_moves.append(en_passant + direction)
	
	var pos = selected_pieces + direction
	if is_empty(pos): _moves.append(pos)
	
	pos = selected_pieces + Vector2(direction.x, 1)
	if is_valid_position(pos):
		if is_enemy(pos): _moves.append(pos)
	pos = selected_pieces + Vector2(direction.x, -1)
	if is_valid_position(pos):
		if is_enemy(pos): _moves.append(pos)
	
	pos = selected_pieces + direction * 2
	if is_first_move and is_empty(pos) and is_empty(selected_pieces + direction): _moves.append(pos)
	
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

func promote(_var: Vector2):
	promotion_square = _var
	
	if GameManager.Q1 == 1:
		board[promotion_square.x][promotion_square.y] = 0
		if !white: board[promotion_square.x][promotion_square.y]= 7
		else:board[promotion_square.x][promotion_square.y] = -7
		promotion_square = null
		display_board()
	else:
		white_pieces.visible = !white
		black_pieces.visible = white

func _on_button_pressed(button):
	var num_char = int(button.name.substr(0,1))
	if !white: board[promotion_square.x][promotion_square.y] = -num_char
	else:board[promotion_square.x][promotion_square.y] = num_char
	white_pieces.visible = false
	black_pieces.visible = false
	promotion_square = null
	display_board()
	maybe_do_ai_move()


func end(winner:bool):
	if winner == true:
		$CanvasLayer/win/Label.text = "White/Player1 WIN!"
		$CanvasLayer/win/Sprite2D.texture = WHITE_KING
		GameManager.PlayerVictory[0] += 1
	else:
		$CanvasLayer/win/Label.text = "Black/Player2 WIN!"
		$CanvasLayer/win/Sprite2D.texture = BLACK_KING
		GameManager.PlayerVictory[1] += 1
	$CanvasLayer/win.visible = true
	
	SaveManager.content_to_save["has_theme"][6] = true
	SaveManager._save()
	
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
	white_pieces.visible = false
	black_pieces.visible = false
	promotion_square = null
	display_board()
