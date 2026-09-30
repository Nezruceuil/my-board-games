extends Control

const BOARD_SIZE = 8
const CELL_WIDTH = 60

const CHESS_TEXTURE = preload("uid://y84bw3qsbxxw")

const MOVES = preload("uid://dgujov8w87o3n")

const WHITE_BISHOP = preload("uid://drcbuc8pqapuk")
const WHITE_KING = preload("uid://y57qje8eqgen")
const WHITE_KNIGHT = preload("uid://twxk4uwbkubu")
const WHITE_PAWN = preload("uid://yad0fhepxuqm")
const BOAT = preload("uid://bou38x6tn55fr")
const WHITE_ROOK = preload("uid://becc2akj8mxvu")

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
var arrows = []
var selected_pieces : Vector2

var promotion_square = null

var dead = []
var points = [0,0,0,0]

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
	board.append([52, 12, 0, 0, 63, 33, 23 , 53])
	board.append([22, 12, 0, 0, 13, 13, 13, 13])
	board.append([32, 12, 0, 0, 0, 0, 0, 0])
	board.append([62, 12, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 14, 64])
	board.append([0, 0, 0, 0, 0, 0, 14, 34])
	board.append([11, 11, 11, 11, 0, 0, 14, 24])
	board.append([51, 21, 31, 61, 0, 0, 14, 54])
	
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
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) - 240, -i * CELL_WIDTH - (CELL_WIDTH / 2) + 240)
			
			if dead.has(str(board[abs(i-7)][j])[-1]):
				holder.modulate = Color(0.307, 0.307, 0.307, 1.0)
			else:
				match str(board[abs(i-7)][j])[-1]:
					"1": holder.modulate = Color(1.0, 0.0, 0.0, 1.0)
					"2": holder.modulate = Color(0.0, 0.463, 1.0, 1.0)
					"3": holder.modulate = Color(1.0, 1.0, 0.0, 1.0)
					"4": holder.modulate = Color(0.0, 0.839, 0.176, 1.0)
			
			if GameManager.Q1 == 3:
				holder.texture = MOVES
				holder.modulate = Color(1.0, 1.0, 1.0, 0.0)
			match str(board[abs(i-7)][j])[0]:
				"6" : holder.texture = WHITE_KING
				"5" : holder.texture = BOAT
				"4" : holder.texture = WHITE_ROOK
				"3" : holder.texture = WHITE_BISHOP
				"2" : holder.texture = WHITE_KNIGHT
				"1" : holder.texture = WHITE_PAWN
				"0" : holder.texture = null
	
	$CanvasLayer/Label.text = "P" + str(turn+1) + " turn"


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.pressed && promotion_square == null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_out()
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 300,0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 300,0) / CELL_WIDTH) - 1

			if (str(board[var2][var1])[-1] == str(turn+1)):
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
	
	delete_dots()
	for i in moves:
		if i.x == var2 and i.y == var1:
			if board[var2][var1] == 61:
				dead.insert(0,"1")
				points[0] -= abs(dead.size()-4) * 0.1
			elif board[var2][var1] == 62:
				dead.insert(0,"2")
				points[1] -= abs(dead.size()-4) * 0.1
			elif board[var2][var1] == 63:
				dead.insert(0,"3")
				points[2] -= abs(dead.size()-4) * 0.1
			elif board[var2][var1] == 64:
				dead.insert(0,"4")
				points[3] -= abs(dead.size()-4) * 0.1
			
			if dead.size() == 3: end(0)
			
			if (not dead.has(str(board[var2][var1])[-1])) or str(board[var2][var1])[0] == "6":
				match str(board[var2][var1])[0]:
					"6": points[turn] += 5
					"5": points[turn] += 5
					"4": points[turn] += 3
					"3": points[turn] += 3
					"2": points[turn] += 3
					"1": points[turn] += 1
			
			if str(board[selected_pieces.x][selected_pieces.y])[0] == "1":
				match turn:
					0: if var2 == 0: promote(Vector2(var2,var1))
					1: if var1 == 7: promote(Vector2(var2,var1))
					2: if var2 == 7: promote(Vector2(var2,var1))
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
			_1.global_position = Vector2(selected_pieces.y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(selected_pieces.x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
			
			var _2 = CHESS_TEXTURE.instantiate()
			$move.add_child(_2)
			_2.texture = MOVES
			_2.modulate = Color(0.776, 0.443, 1.0, 0.588)
			_2.global_position = Vector2(var1 * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(var2-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
			
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
				"5": text = "boat "
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
			text += str(round(abs(int(var2)-8)))
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
		"5": _moves = get_rook_moves()
		"6": _moves = get_king_moves()
		
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
	if is_empty(pos) and is_valid_position(pos): _moves.append(pos)
	if GameManager.Q1 == 1:
		pos = selected_pieces + direction * 2
		if is_empty(pos) and is_valid_position(pos): _moves.append(pos)
	
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
	if pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE: return true
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
			board[promotion_square.x][promotion_square.y]= 41
		1:
			await get_tree().create_timer(0.05).timeout
			board[promotion_square.x][promotion_square.y]= 42
		2:
			await get_tree().create_timer(0.05).timeout
			board[promotion_square.x][promotion_square.y]= 43
		3:
			await get_tree().create_timer(0.05).timeout
			board[promotion_square.x][promotion_square.y]= 44
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
		for i in 3:
			if points[i] > points[winner]:
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
