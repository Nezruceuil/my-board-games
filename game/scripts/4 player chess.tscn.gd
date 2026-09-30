extends Control

const BOARD_SIZE = 12
const CELL_WIDTH = 50

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


# Vars first letter
# 0 = empty
# 6 = white king
# 5 = white queen
# 4 = white rook
# 3 = white bishop
# 2 = white knight
# 1 = white pawn


var board : Array
var turn = 0
var state : bool = false
var moves = []
var selected_pieces : Vector2

var promotion_square = null

var dead = []

var rng = RandomNumberGenerator.new()

var drawing = []

var time = [60,60,60,60]

func _process(delta: float) -> void:
	if not GameManager.Q2 == 2 and not time[turn] < 0:
		$CanvasLayer/Timer.visible = true
		
		if turn == 0:
			time[0] -= delta
			$CanvasLayer/Timer.text = "TIME LEFT: " + str(round(time[0] * 100)/100)
		elif turn == 1:
			time[1] -= delta
			$CanvasLayer/Timer.text = "TIME LEFT: " + str(round(time[1] * 100)/100)
		elif turn == 2:
			time[2] -= delta
			$CanvasLayer/Timer.text = "TIME LEFT: " + str(round(time[2] * 100)/100)
		else:
			time[3] -= delta
			$CanvasLayer/Timer.text = "TIME LEFT: " + str(round(time[3] * 100)/100)
		
		if time[0] < 0 and not dead.has("1"):
			dead.insert(0,"1")
			if turn == 3:
				turn = 0
			else:
				turn += 1
			if dead.has(str(turn+1)):
				while dead.has(str(turn+1)):
					if turn == 3:
						turn = 0
					else:
						turn += 1
			display_board()
		elif time[1] < 0 and not dead.has("2"):
			dead.insert(0,"2")
			if turn == 3:
				turn = 0
			else:
				turn += 1
			if dead.has(str(turn+1)):
				while dead.has(str(turn+1)):
					if turn == 3:
						turn = 0
					else:
						turn += 1
			display_board()
		elif time[2] < 0 and not dead.has("3"):
			dead.insert(0,"3")
			if turn == 3:
				turn = 0
			else:
				turn += 1
			if dead.has(str(turn+1)):
				while dead.has(str(turn+1)):
					if turn == 3:
						turn = 0
					else:
						turn += 1
			display_board()
		elif time[3] < 0 and not dead.has("4"):
			dead.insert(0,"4")
			if turn == 3:
				turn = 0
			else:
				turn += 1
			if dead.has(str(turn+1)):
				while dead.has(str(turn+1)):
					if turn == 3:
						turn = 0
					else:
						turn += 1
			display_board()
	else: $CanvasLayer/Timer.visible = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.Bots_difficulty == true: ChessAi.time_budget_ms = 8000
	else: ChessAi.time_budget_ms = 1000
	
	if GameManager.Q2 == 3: time = [300,300,300,300]
	else: $CanvasLayer/Timer.visible = false
	board.append([00, 00 ,43, 23, 33 , 53, 63, 33, 23, 43, 00, 00])
	board.append([00, 00, 13, 13, 13, 13, 13, 13, 13, 13, 00, 00])
	board.append([42, 12, 00, 00, 00, 00, 00, 00, 00, 00, 14, 44])
	board.append([22, 12, 00, 00, 00, 00, 00, 00, 00, 00, 14, 24])
	board.append([32, 12, 00, 00, 00, 00, 00, 00, 00, 00, 14, 34])
	board.append([52, 12, 00, 00, 00, 00, 00, 00, 00, 00, 14, 54])
	board.append([62, 12, 00, 00, 00, 00, 00, 00, 00, 00, 14, 64])
	board.append([32, 12, 00, 00, 00, 00, 00, 00, 00, 00, 14, 34])
	board.append([22, 12, 00, 00, 00, 00, 00, 00, 00, 00, 14, 24])
	board.append([42, 12, 00, 00, 00, 00, 00, 00, 00, 00, 14, 44])
	board.append([00, 00, 11, 11, 11, 11, 11, 11, 11, 11, 00, 00])
	board.append([00, 00, 41, 21, 31, 51, 61, 31, 21, 41, 00, 00])
	
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
			var holder = CHESS_TEXTURE.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) - 301, -i * CELL_WIDTH - (CELL_WIDTH / 2) + 301)
			
			holder.rotation_degrees = 90 * (turn)
			
			if dead.has(str(board[abs(i-11)][j])[-1]):
				board[abs(i-11)][j] = 0
			else:
				match str(board[abs(i-11)][j])[-1]:
					"1": holder.modulate = Color(1.0, 0.0, 0.0, 1.0)
					"2": holder.modulate = Color(0.0, 0.463, 1.0, 1.0)
					"3": holder.modulate = Color(1.0, 1.0, 0.0, 1.0)
					"4": holder.modulate = Color(0.0, 0.839, 0.176, 1.0)
			
			if GameManager.Q1 == 3:
				holder.texture = MOVES
				holder.modulate = Color(1.0, 1.0, 1.0, 0.0)
			match str(board[abs(i-11)][j])[0]:
				"6" : holder.texture = WHITE_KING
				"5" : holder.texture = WHITE_QUEEN
				"4" : holder.texture = WHITE_ROOK
				"3" : holder.texture = WHITE_BISHOP
				"2" : holder.texture = WHITE_KNIGHT
				"1" : holder.texture = WHITE_PAWN
				"0" : holder.texture = null
	
	$CanvasLayer/Label.text = "P" + str(turn+1) + " turn"
	$Camera2D.rotation_degrees = 90 * (turn)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.pressed && promotion_square == null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_out()
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 300,0) / CELL_WIDTH)
			var var2 = (snapped(get_global_mouse_position().y + 300,0) / CELL_WIDTH)

			if (str(board[var2][var1])[-1] == str(turn+1)):
				selected_pieces = Vector2(var2, var1)
				show_options()
				state = true
			elif state == true: set_move(var2,var1)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_mouse_out()
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 300,0) / CELL_WIDTH) 
			var var2 = (snapped(get_global_mouse_position().y + 300,0) / CELL_WIDTH)
			
			show_drawing(var2,var1)

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
			child.global_position = Vector2(drawing[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 300,(abs(drawing[i].x-11)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 300)
			child.scale = Vector2(3.3,3.3)


func is_mouse_out():
	if get_global_mouse_position().x < 300 and get_global_mouse_position().x > -300 and get_global_mouse_position().y > -300 and get_global_mouse_position(). y < 300 : return true
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
		holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH/2) - 300,(abs(i.x-11)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 300)
		holder.scale = Vector2(3.3,3.3)

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var2,var1):
	
	delete_dots()
	for i in moves:
		if i.x == var2 and i.y == var1:
			if board[var2][var1] == 61:
				dead.insert(0,"1")
			elif board[var2][var1] == 62:
				dead.insert(0,"2")
			elif board[var2][var1] == 63:
				dead.insert(0,"3")
			elif board[var2][var1] == 64:
				dead.insert(0,"4")
			
			if dead.size() == 3: end(0)
			
			
			if str(board[selected_pieces.x][selected_pieces.y])[0] == "1":
				match turn:
					0: if var2 == 0: promote(Vector2(var2,var1))
					1: if var1 == 11: promote(Vector2(var2,var1))
					2: if var2 == 11: promote(Vector2(var2,var1))
					3: if var1 == 0: promote(Vector2(var2,var1))
			
			
			board[var2][var1] = board[selected_pieces.x][selected_pieces.y]
			board[selected_pieces.x][selected_pieces.y] = 0
			
			drawing = []
			for child in $move.get_children():
				child.queue_free()
			
			var _1 = CHESS_TEXTURE.instantiate()
			$move.add_child(_1)
			_1.texture = MOVES
			_1.modulate = Color(0.898, 0.776, 1.0, 0.588)
			_1.global_position = Vector2(selected_pieces.y * CELL_WIDTH + (CELL_WIDTH/2) - 300,(abs(selected_pieces.x-11)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 300)
			
			var _2 = CHESS_TEXTURE.instantiate()
			$move.add_child(_2)
			_2.texture = MOVES
			_2.modulate = Color(0.776, 0.443, 1.0, 0.588)
			_2.global_position = Vector2(var1 * CELL_WIDTH + (CELL_WIDTH/2) - 300,(abs(var2-11)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 300)
			
			if turn == 3:
				turn = 0
			else:
				turn += 1
			if dead.has(str(turn+1)):
				while dead.has(str(turn+1)):
					if turn == 3:
						turn = 0
					else:
						turn += 1
			display_board()
			
			var text = ""
			match str(abs(board[var2][var1]))[0]:
				"2": text = "knight "
				"3": text = "bishop "
				"4": text = "rook "
				"5": text = "queen "
				"6": text = "king "
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
				9: text += "j"
				10: text += "k"
				11: text += "l"
			text += str(round(abs(int(var2)-11))+1)
			$CanvasLayer/buttons/chat.text += "
			" + text
			
			break
	state = false


func get_moves():
	var _moves = []
	match str(abs(board[selected_pieces.x][selected_pieces.y]))[0]:
		"1": _moves = get_pawn_moves()
		"2": _moves = get_knight_moves()
		"3": _moves = get_bishop_moves()
		"4": _moves = get_rook_moves()
		"5": _moves = get_queen_moves()
		"6": _moves = get_king_moves()
		
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

func get_king_moves():
	var _moves = []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
	
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
	
	if turn == 0: direction = Vector2(-1, 0)
	elif turn == 1: direction = Vector2(0, 1)
	elif turn == 2: direction = Vector2(1, 0)
	else: direction = Vector2(0, -1)
	
	
	var pos = selected_pieces + direction
	if is_valid_position(pos): if is_empty(pos): _moves.append(pos)
	
	if GameManager.Q1 == 1 or ((turn == 0 and selected_pieces.x == 10) or (turn == 2 and selected_pieces.x == 1) or (turn == 1 and selected_pieces.y == 1) or (turn == 3 and selected_pieces.y == 10)):
		if is_valid_position(pos): if is_empty(pos):
			pos = selected_pieces + direction * 2
			if is_valid_position(pos): if is_empty(pos): _moves.append(pos)
	
	if turn % 2 == 0:
		pos = selected_pieces + Vector2(direction.x, 1)
		if is_valid_position(pos):
			if is_enemy(pos): _moves.append(pos)
		pos = selected_pieces + Vector2(direction.x, -1)
		if is_valid_position(pos):
			if is_enemy(pos): _moves.append(pos)
	else:
		pos = selected_pieces + Vector2(1, direction.y)
		if is_valid_position(pos):
			if is_enemy(pos): _moves.append(pos)
		pos = selected_pieces + Vector2(-1, direction.y)
		if is_valid_position(pos):
			if is_enemy(pos): _moves.append(pos)
	
	
	return _moves


func is_valid_position(pos : Vector2):
	if pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE:
		if not ((pos.x == 0 or pos.x == 1 or pos.x == 10 or pos.x == 11) and (pos.y == 0 or pos.y == 1 or pos.y == 10 or pos.y == 11)): return true
	return false
func is_empty(pos: Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false
func is_enemy(pos : Vector2):
	if not str(board[pos.x][pos.y])[-1] == str(turn+1) and not str(board[pos.x][pos.y])[-1] == "0": return true
	return false

func promote(_var: Vector2):
	promotion_square = _var
	
	
	board[promotion_square.x][promotion_square.y] = 0
	match turn:
		0:
			await get_tree().create_timer(0.05).timeout
			board[promotion_square.x][promotion_square.y]= 51
		1:
			await get_tree().create_timer(0.05).timeout
			board[promotion_square.x][promotion_square.y]= 52
		2:
			await get_tree().create_timer(0.05).timeout
			board[promotion_square.x][promotion_square.y]= 53
		3:
			await get_tree().create_timer(0.05).timeout
			board[promotion_square.x][promotion_square.y]= 54
	promotion_square = null
	display_board()

func _on_button_pressed(button):
	var num_char = int(button.name.substr(0,1))
	if turn == 1: board[promotion_square.x][promotion_square.y] = -num_char
	else:board[promotion_square.x][promotion_square.y] = num_char
	white_pieces.visible = false
	black_pieces.visible = false
	promotion_square = null
	display_board()


func end(winner):
	if winner == 0:
		
		winner = 0
		for i in 4:
			if not dead.has(str(i+1)):
				winner = i
	
	winner += 1
	
	if winner == 1:
		$CanvasLayer/win/Label.text = "Red/Player1 WIN!"
		$CanvasLayer/win/Sprite2D.texture = WHITE_KING
		$CanvasLayer/win/Sprite2D.modulate = Color(1.0, 0.0, 0.0, 1.0)
		GameManager.PlayerVictory[0] += 1
	elif winner == 2:
		$CanvasLayer/win/Label.text = "Blue/Player2 WIN!"
		GameManager.PlayerVictory[1] += 1
		$CanvasLayer/win/Sprite2D.modulate = Color(0.0, 0.463, 1.0, 1.0)
	elif winner == 3:
		$CanvasLayer/win/Label.text = "Yellow/Player3 WIN!"
		GameManager.PlayerVictory[1] += 1
		$CanvasLayer/win/Sprite2D.modulate = Color(1.0, 1.0, 0.0, 1.0)
	else:
		$CanvasLayer/win/Label.text = "Green/Player4 WIN!"
		GameManager.PlayerVictory[1] += 1
		$CanvasLayer/win/Sprite2D.modulate = Color(0.0, 0.839, 0.176, 1.0)

	$CanvasLayer/win.visible = true
	
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://game/menu.tscn")
