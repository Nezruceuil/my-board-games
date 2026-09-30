extends Control

const BOARD_SIZE = 8
const CELL_WIDTH = 60

const CHESS_TEXTURE = preload("uid://y84bw3qsbxxw")

const BLACK_KING = preload("uid://bxfchep71u5pt")
const BLACK_QUEEN = preload("uid://dvqdryfjf2fg0")
const MOVES = preload("uid://dgujov8w87o3n")

const WHITE_KING = preload("uid://y57qje8eqgen")
const WHITE_QUEEN = preload("uid://jmtskg520hkl")

@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dots


var movements = []

var board : Array
var white : bool = false
var moves = []
var selected_pieces : Vector2

var total_troops = Vector2(0,0)

var rng = RandomNumberGenerator.new()

var drawing = []

var time = Vector2(60,60)


func _process(delta: float) -> void:
	if not (time.x == 0 or time.y == 0):
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
	if GameManager.Q1 == 1:
		match rng.randi_range(0,8):
			0: movements = [0,1,2,3,14,15]
			1: movements = [4,5,10,11]
			2: movements = [6,7,8,9,16,17,18,19]
			3: movements = [6,7,8,9,10,11]
			4: movements = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19] #
			5: movements = [4,5,14,15]
			6: movements = [4,5,14,15,6,7,8,9]
			7: movements = [6,7,8,9,10,11,4,5]
			8: movements = [0,1,2,3,6,7,8,9,14,15]
	else:
		for i in 20:
			var count = abs(GameManager.Q1 - 2) * 4 + 1
			if not movements.size() > (GameManager.Q1 + 1) * 4 - 3:
				if rng.randi_range(0,count+1) == 0:
					movements += [i]
					count += 1
				elif not count == 0: count -= 1
		if movements.size() < (GameManager.Q1 + 1) * 4 - 3:
			for i in ((GameManager.Q1 + 1) * 4 - 3) -  movements.size():
				movements += [rng.randi_range(0,19)]
	print(movements.size())
	print(movements)
	
	if GameManager.Q2 == 1: time = Vector2(60,60)
	elif GameManager.Q2 == 2: time = Vector2(300,300)
	elif GameManager.Q2 == 3: time = Vector2(600,600)
	
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	
	
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
	delete_dots()
	
	moves = []
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = CHESS_TEXTURE.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) - 240, -i * CELL_WIDTH - (CELL_WIDTH / 2) + 240)
			if white: holder.rotation_degrees = 180
			
			match board[abs(i-7)][j]:
				-5 : holder.texture = BLACK_QUEEN
				0 : holder.texture = null
				5 : holder.texture = WHITE_QUEEN
			
			if not board[abs(i-7)][j] == 0:
				selected_pieces = Vector2(abs(i-7),j)
				moves += get_moves()
				moves += [Vector2(abs(i-7),j)]
	
	if white:
		$CanvasLayer/Label.text = "P2 turn"
		$Camera2D.rotation_degrees = 180
	else:
		$CanvasLayer/Label.text = "P1 turn"
		$Camera2D.rotation_degrees = 0
	
	show_dots()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_out()
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 300,0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 300,0) / CELL_WIDTH) - 1

			if board[var2][var1] == 0 and moves.has(Vector2(var2,var1)) == false:
				selected_pieces = Vector2(var2, var1)
				if white:
					total_troops.y += 1
					board[var2][var1] = -5
				else:
					total_troops.x += 1
					board[var2][var1] = 5
				display_board()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_mouse_out()
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 300,0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 300,0) / CELL_WIDTH) - 1
			
			if not board[var2][var1] == 0:
				if white:
					total_troops.y -= 1
					board[var2][var1] = -5
				else:
					total_troops.x -= 1
					
					board[var2][var1] = 5
					
				board[var2][var1] = 0
				
				display_board()

func is_mouse_out():
	if get_global_mouse_position().x < 240 and get_global_mouse_position().x > -240 and get_global_mouse_position().y > -240 and get_global_mouse_position(). y < 240 : return true
	return false


func show_dots():
	delete_dots()
	for i in 8:
		for j in 8:
			var ok = true
			for m in moves.size():
				if moves[m] == Vector2(i,j):
					ok = false
			if ok == true:
				var holder = CHESS_TEXTURE.instantiate()
				dots.add_child(holder)
				holder.texture = MOVES
				holder.modulate = Color(1.0, 1.0, 1.0, 0.75)
				holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(i-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)

func delete_dots():
	for child in dots.get_children():
		child.queue_free()


func get_moves():
	var _moves = []
	for i in movements.size():
		match movements[i]:
			0:
				_moves += get_king_moves(0)
				_moves += get_king_moves(3)
			1:
				_moves += get_king_moves(1)
				_moves += get_king_moves(2)
			2:
				_moves += get_king_moves(4)
				_moves += get_king_moves(5)
			3:
				_moves += get_king_moves(6)
				_moves += get_king_moves(7)
			
			4:
				_moves += get_bishop_moves(0)
				_moves += get_bishop_moves(3)
			5:
				_moves += get_bishop_moves(1)
				_moves += get_bishop_moves(2)
			
			6:
				_moves += get_knight_moves(0)
				_moves += get_knight_moves(5)
			7:
				_moves += get_knight_moves(1)
				_moves += get_knight_moves(4)
			8:
				_moves += get_knight_moves(2)
				_moves += get_knight_moves(7)
			9:
				_moves += get_knight_moves(3)
				_moves += get_knight_moves(6)
			
			10:
				_moves += get_pizza_moves(0)
				_moves += get_pizza_moves(2)
			11:
				_moves += get_pizza_moves(1)
				_moves += get_pizza_moves(3)
			
			12:
				_moves += get_long_pizza_moves(0)
				_moves += get_long_pizza_moves(2)
			13:
				_moves += get_long_pizza_moves(1)
				_moves += get_long_pizza_moves(3)
			
			14:
				_moves += get_rook_moves(0)
				_moves += get_rook_moves(1)
			15:
				_moves += get_rook_moves(2)
				_moves += get_rook_moves(3)
			
			16:
				_moves += get_long_knight_moves(0)
				_moves += get_long_knight_moves(5)
			17:
				_moves += get_long_knight_moves(1)
				_moves += get_long_knight_moves(4)
			18:
				_moves += get_long_knight_moves(2)
				_moves += get_long_knight_moves(7)
			19:
				_moves += get_long_knight_moves(3)
				_moves += get_long_knight_moves(6)
	return _moves


func get_rook_moves(i):
	var _moves = []
	var directions = [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	
	var pos = selected_pieces
	pos += directions[i]
	while is_valid_position(pos):
		if is_empty(pos): _moves.append(pos)
		elif is_enemy(pos):
			_moves.append(pos)
			break
		else: break
		
		pos += directions[i]
	
	return _moves

func get_bishop_moves(i):
	var _moves = []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1)]
	
	var pos = selected_pieces
	pos += directions[i]
	while is_valid_position(pos):
		if is_empty(pos): _moves.append(pos)
		elif is_enemy(pos):
			_moves.append(pos)
			break
		else: break
		
		pos += directions[i]
	
	return _moves

func get_knight_moves(i):
	var _moves = []
	var directions = [Vector2(2,1),Vector2(2,-1),Vector2(1,2),Vector2(-1,2),
						Vector2(-2,1),Vector2(-2,-1),Vector2(1,-2),Vector2(-1,-2)]
	
	var pos = selected_pieces
	pos += directions[i]
	if is_valid_position(pos):
		if is_empty(pos): _moves.append(pos)
		elif is_enemy(pos):
			_moves.append(pos)
	
	return _moves

func get_long_knight_moves(i):
	var _moves = []
	var directions = [Vector2(3,1),Vector2(3,-1),Vector2(1,3),Vector2(-1,3),
						Vector2(-3,1),Vector2(-3,-1),Vector2(1,-3),Vector2(-1,-3)]
	
	
	var pos = selected_pieces
	pos += directions[i]
	if is_valid_position(pos):
		if is_empty(pos): _moves.append(pos)
		elif is_enemy(pos):
			_moves.append(pos)
	
	return _moves

func get_pizza_moves(i):
	var _moves = []
	var directions = [Vector2(2,0),Vector2(0,2),Vector2(-2,0),Vector2(0,-2)]
	
	var pos = selected_pieces
	pos += directions[i]
	if is_valid_position(pos):
		if is_empty(pos): _moves.append(pos)
		elif is_enemy(pos):
			_moves.append(pos)
	
	return _moves

func get_long_pizza_moves(i):
	var _moves = []
	var directions = [Vector2(3,0),Vector2(0,3),Vector2(-3,0),Vector2(0,-3)]
	
	var pos = selected_pieces
	pos += directions[i]
	if is_valid_position(pos):
		if is_empty(pos): _moves.append(pos)
		elif is_enemy(pos):
			_moves.append(pos)
	
	return _moves

func get_king_moves(i):
	var _moves = []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	var pos = selected_pieces + directions[i]
	if is_valid_position(pos):
		if is_empty(pos): _moves.append(pos)
		elif is_enemy(pos):
			_moves.append(pos)
	
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



func end(winner:bool):
	print(total_troops)
	if winner == true:
		$CanvasLayer/win/Label2.text = "With " + str(int(total_troops.x)) + " pieces against " + str(int(total_troops.y))
		$CanvasLayer/win/Label.text = "White/Player1 WIN!"
		$CanvasLayer/win/Sprite2D.texture = WHITE_KING
		GameManager.PlayerVictory[0] += 1
	else:
		$CanvasLayer/win/Label2.text = "With " + str(int(total_troops.y)) + " pieces against " + str(int(total_troops.x))
		$CanvasLayer/win/Label.text = "Black/Player2 WIN!"
		$CanvasLayer/win/Sprite2D.texture = BLACK_KING
		GameManager.PlayerVictory[1] += 1
	$CanvasLayer/win.visible = true
	
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://game/menu.tscn")

func _on_next_player_pressed():
	if !white:
		white = true
		
		board.clear()
		
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		moves = []
		display_board()
		delete_dots()
	else:
		if total_troops.y > total_troops.x: end(false)
		elif total_troops.x > total_troops.y: end(true)
		else:
			$CanvasLayer/win/Label.text = "DRAW!"
			$CanvasLayer/win/Sprite2D.texture = MOVES
			GameManager.PlayerVictory[0] += 0.5
			GameManager.PlayerVictory[1] += 0.5
			$CanvasLayer/win/Label2.text = str(int(total_troops.x)) + " against " + str(int(total_troops.y))
			$CanvasLayer/win.visible = true
			
			await get_tree().create_timer(5).timeout
			get_tree().change_scene_to_file("res://game/menu.tscn")
