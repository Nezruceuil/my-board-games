extends Control

const BOARD_SIZE = 8
const CELL_WIDTH = 60

const CHESS_TEXTURE = preload("uid://y84bw3qsbxxw")

const MOVES = preload("uid://dgujov8w87o3n")

const BLACK_QUEEN = preload("uid://dvqdryfjf2fg0")
const WHITE_QUEEN = preload("uid://jmtskg520hkl")
const FLAME = preload("uid://cu6gqucgh4jss")

@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dots

@onready var white_pieces: Control = $CanvasLayer/White_pieces
@onready var black_pieces: Control = $CanvasLayer/Black_pieces


# Vars
# -1 = black queen
# 0 = empty
# 1 = white queen
# 2 = FIRE!

var move = false

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
	
	board.append([0, 0, -1, 0, 0, -1, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([-1, 0, 0, 0, 0, 0, 0, -1])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([1, 0, 0, 0, 0, 0, 0, 1])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 1, 0, 0, 1, 0, 0])
	
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
			if white: holder.rotation_degrees = 180
			
			if GameManager.Q1 == 3:
				holder.texture = MOVES
				holder.modulate = Color(1.0, 1.0, 1.0, 0.0)
			match board[abs(i-7)][j]:
				-1 : holder.texture = BLACK_QUEEN
				0 : holder.texture = null
				1 : holder.texture = WHITE_QUEEN
				2 : holder.texture = FLAME
	
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

			if move == true:
				set_move(var2,var1)
			else:
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
		if move == true: holder.modulate = Color(1.0, 0.0, 0.0, 0.788)

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var2,var1):
	
	var just_now = false
	delete_dots()
	for i in moves:
		if i.x == var2 and i.y == var1:
			
			if !just_now: en_passant = null
			
			if move == true:
				board[var2][var1] = 2
			else:
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
			
			
			if move == true:
				white = !white
			move = !move
			
			display_board()
			
			var text = ""
			if move == false:
				text = "fire at "
			else:
				text = "queen "
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
	
	can_move()
	if state == true:
		if move == true:
			selected_pieces = Vector2(var2,var1)
			show_options()
			state = false
		state = false
	elif move == true:
		show_options()


func get_moves():
	if not board[selected_pieces.x][selected_pieces.y] == 2:
		var _moves = []
		_moves = get_queen_moves()
		
		return _moves
	return []

func get_queen_moves():
	var _moves = []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	if GameManager.Q1 == 1:
		if !move: directions = [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
		else: directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1)]
		
	
	for i in directions:
		var pos = selected_pieces
		pos += i
		while is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			else: break
			
			pos += i
	
	return _moves


func is_valid_position(pos : Vector2):
	if pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE: return true
	return false
func is_empty(pos: Vector2):
	if board[pos.x][pos.y] == 0: return true
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


func end(winner:bool):
	if winner == true:
		$CanvasLayer/win/Label.text = "White/Player1 WIN!"
		$CanvasLayer/win/Sprite2D.texture = WHITE_QUEEN
		GameManager.PlayerVictory[0] += 1
	else:
		$CanvasLayer/win/Label.text = "Black/Player2 WIN!"
		$CanvasLayer/win/Sprite2D.texture = BLACK_QUEEN
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


func can_move():
	var can_move = false
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	for x in 8:
		if can_move == true: break
		for y in 8:
			if (white and board[x][y] == -1) or (!white and board[x][y] == 1):
				if can_move == true: break
				for i in directions:
					var pos = Vector2(x,y) + i
					if is_valid_position(pos):
						if is_empty(pos):
							can_move = true
							break
	
	if can_move == false:
		if white: end(true)
		else: end(false)
