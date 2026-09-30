extends Control

const BOARD_SIZE = 7
const CELL_WIDTH = 60

const CHESS_TEXTURE = preload("uid://y84bw3qsbxxw")

const MOVES = preload("uid://dgujov8w87o3n")

var corner = true

@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dots

@onready var white_pieces: Control = $CanvasLayer/White_pieces
@onready var black_pieces: Control = $CanvasLayer/Black_pieces

const WHITE_PAWN = preload("uid://yad0fhepxuqm")
const BLACK_PAWN = preload("uid://cys3ofokiewp6")
const WHITE_KING = preload("uid://y57qje8eqgen")




# Vars
# -1 = black
# 0 = empty
# 1 = white


var board : Array
var white : bool = true
var state : bool = false
var moves = []
var dir = []
var selected_pieces = Vector2(-1,-1)


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
			end(1)
		elif time.y < 0:
			time.x = 0
			time.y = 0
			end(0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.Bots_difficulty == true: ChessAi.time_budget_ms = 8000
	else: ChessAi.time_budget_ms = 1000
	
	if GameManager.Q2 == 1: time = Vector2(60,60)
	elif GameManager.Q2 == 3: time = Vector2(300,300)
	else: $CanvasLayer/Timer.visible = false
	
	if GameManager.Q1 == 1:
		corner = true
		white = false
		board.append([0, 0, -1, -1, -1, 0, 0])
		board.append([0, 0, 0, -1, 0, 0, 0])
		board.append([-1, 0, 1, 1, 1, 0, -1])
		board.append([-1, -1, 1, 2, 1, -1, -1])
		board.append([-1, 0, 1, 1, 1, 0, -1])
		board.append([0, 0, 0, -1, 0, 0, 0])
		board.append([0, 0, -1, -1, -1, 0, 0])
	elif GameManager.Q1 == 2:
		corner = false
		board.append([0, 0, -1, 0, -1, 0, 0])
		board.append([0, -1, 0, 1, 0, -1, 0])
		board.append([-1, 0, 0, 1, 0, 0, -1])
		board.append([0, 1, 1, 2, 1, 1, 0])
		board.append([-1, 0, 0, 1, 0, 0, -1])
		board.append([0, -1, 0, 1, 0, -1, 0])
		board.append([0, 0, -1, 0, -1, 0, 0])
	else:
		corner = true
		board.append([0, 0, 0, -1, 0, 0, 0])
		board.append([0, 0, 0, -1, 0, 0, 0])
		board.append([0, 0, 0, 1, 0, 0, 0])
		board.append([-1, -1, 1, 2, 1, -1, -1])
		board.append([0, 0, 0, 1, 0, 0, 0])
		board.append([0, 0, 0, -1, 0, 0, 0])
		board.append([0, 0, 0, -1, 0, 0, 0])
	
	display_board()
	
	if corner == false:
		$board/x1.visible = false
		$board/x2.visible = false
		$board/x3.visible = false
		$board/x4.visible = false


func display_board():
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = CHESS_TEXTURE.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) - 210, -i * CELL_WIDTH - (CELL_WIDTH / 2) + 210)
			
			match board[abs(i-6)][j]:
				-1 : holder.texture = BLACK_PAWN
				0 : holder.texture = null
				1 : holder.texture = WHITE_PAWN
				2 : holder.texture = WHITE_KING
	
	if white:
		$CanvasLayer/Label.text = "P2 turn"
	else:
		$CanvasLayer/Label.text = "P1 turn"


func _input(event: InputEvent) -> void:
	if event.is_action("Delete"):
		drawing = []
		arrows = []
		for child in $move.get_children():
			child.queue_free()
		for child in $arrows.get_children():
			child.queue_free()
	elif event is InputEventMouseButton && event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_out()
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 270,0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 270,0) / CELL_WIDTH) - 1

			if !state and (white && board[var2][var1] < 0) or !state and (!white && board[var2][var1] > 0):
				selected_pieces = Vector2(var2, var1)
				show_options()
				state = true
			elif state == true: set_move(var2,var1)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 270, 0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 270, 0) / CELL_WIDTH) - 1
			await get_tree().create_timer(0.2).timeout
			var _var1 = (snapped(get_global_mouse_position().x + 270, 0) / CELL_WIDTH) - 1
			var _var2 = (snapped(get_global_mouse_position().y + 270, 0) / CELL_WIDTH) - 1

			if Vector2(var2, var1) == Vector2(_var2, _var1):
				show_drawing(var2, var1)
			else:
				_var1 = -1
				while not (_var1 == (snapped(get_global_mouse_position().x + 270, 0) / CELL_WIDTH) - 1 \
					and _var2 == (snapped(get_global_mouse_position().y + 270, 0) / CELL_WIDTH) - 1):
					_var1 = (snapped(get_global_mouse_position().x + 270, 0) / CELL_WIDTH) - 1
					_var2 = (snapped(get_global_mouse_position().y + 270, 0) / CELL_WIDTH) - 1
					await get_tree().create_timer(0.25).timeout
				_var1 = (snapped(get_global_mouse_position().x + 270, 0) / CELL_WIDTH) - 1
				_var2 = (snapped(get_global_mouse_position().y + 270, 0) / CELL_WIDTH) - 1

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
			child.global_position = Vector2(arrows[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 210,(abs(arrows[i].x-6)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 210)
			child.rotation = arrows[i].z
			child.move_local_x(abs(arrows[i].w - 7))
			
			var child2 = CHESS_TEXTURE.instantiate()
			$arrows.add_child(child2)
			child2.texture = ARROWS_2
			child2.modulate = GameManager.color
			child2.rotation = arrows[i].z
			child2.global_position = Vector2(arrows[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 210,(abs(arrows[i].x-6)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 210)
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
			child.global_position = Vector2(drawing[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 210,(abs(drawing[i].x-6)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 210)


func is_mouse_out():
	if get_global_mouse_position().x < 210 and get_global_mouse_position().x > -210 and get_global_mouse_position().y > -210 and get_global_mouse_position(). y < 210 : return true
	return false

func show_options():
	moves = get_moves()
	if moves == []:
		state = false
		delete_dots()
	else:
		show_dots()

func show_dots():
	delete_dots()
	for i in moves:
		var holder = CHESS_TEXTURE.instantiate()
		dots.add_child(holder)
		holder.texture = MOVES
		holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH/2) - 210,(abs(i.x-6)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 210)

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var2,var1):
	
	delete_dots()
	for i in moves:
		if i.x == var2 and i.y == var1:
			
			if corner == true:
				if (var2 == 6 or var2 == 0) and (var1 == 6 or var1 == 0):
					end(1)
			else:
				if white == false:
					if board[selected_pieces.x][selected_pieces.y] == 2:
						if (var2 == 6 or var2 == 0) or (var1 == 6 or var1 == 0):
							end(1)
			
			var selected_piece = selected_pieces
			board[var2][var1] = board[selected_pieces.x][selected_pieces.y]
			board[selected_pieces.x][selected_pieces.y] = 0
			selected_pieces = i
			
			var dir = get_other_moves()
			
			selected_pieces = selected_piece
			
			
			var pos = Vector2()
			
			for k in dir.size():
				pos = Vector2(var2,var1)
				pos += dir[k]
				if not board[pos.x][pos.y] == 2:
					board[pos.x][pos.y] = 0
				elif GameManager.Q1 == 3:
					end(0)
			
			
			drawing = []
			arrows = []
			for child in $move.get_children():
				child.queue_free()
			for child in $arrows.get_children():
				child.queue_free()
			
			var _1 = CHESS_TEXTURE.instantiate()
			$move.add_child(_1)
			_1.texture = MOVES
			_1.modulate = Color(0.776, 0.443, 1.0, 0.784)
			_1.global_position = Vector2(var1 * CELL_WIDTH + (CELL_WIDTH/2) - 210,(abs(var2-6)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 210)
			
			
			if white:
				for x in 7:
					for y in 7:
						if board[x][y] == 2:
							if is_king_safe(Vector2(x,y)) == false:
								end(0)
							break
			
			white = !white
			display_board()
			
			var text = ""
			match board[var2][var1]:
				-1: text = "black pawn "
				1: text = "white pawn "
				2: text = "white king "
			match int(var1):
				0: text += "a"
				1: text += "b"
				2: text += "c"
				3: text += "d"
				4: text += "e"
				5: text += "f"
				6: text += "g"
				7: text += "h"
			text += str(round(abs(int(var2)-7)))
			$CanvasLayer/buttons/chat.text += "
			" + text
			
			break
	state = false
	delete_dots()

func is_king_safe(king_pos):
	var direction = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	var other_direction = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	
	var pos = Vector2()
	var need = 0
	var has = 0
	
	for i in direction:
		pos = king_pos
		pos += i
		while is_valid_position(pos) and not is_empty(pos) and not is_enemy(pos) and need == has:
			
			for j in other_direction:
				var other_pos = pos
				other_pos += j
				while is_valid_position(other_pos) and not is_empty(other_pos) and not is_enemy(other_pos):
					
					
					other_pos += j
				need += 1
				if not is_empty(other_pos) or not is_valid_position(other_pos):
					has += 1
				else:
					break
			
			pos += i
		need += 1
		if not is_empty(pos) or not is_valid_position(pos):
			has += 1
	
	
	if need == has:
		return false
	
	return true

func get_moves():
	moves = []
	dir = []
	var _moves = []
	var pos = Vector2()
	
	var direction = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	
	if GameManager.Q1 == 1:
		for i in direction:
			pos = selected_pieces
			pos += i
			if is_empty(pos): _moves.append(pos)
	else:
		for i in direction:
			pos = selected_pieces
			pos += i
			while is_valid_position(pos) or pos.x == 3 and pos.y == 3:
				if is_empty(pos): _moves.append(pos)
				else: break
				
				pos += i
	
	return _moves

func get_other_moves():
	var _moves = []
	var pos = Vector2()
	var direction = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	for i in direction.size():
		pos = Vector2(selected_pieces.x,selected_pieces.y) + direction[i]
		if (not is_enemy(pos) and is_enemy(pos + direction[i])) or (not is_enemy(pos) and not is_empty(pos) and is_enemy(pos + direction[i])):
			pos += direction[i]
			_moves.append(direction[i])
	
	return _moves


func is_valid_position(pos : Vector2):
	
	if pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE:
		if pos.x == 3 and pos.y == 3:
			return false
		if corner == false or board[selected_pieces.x][selected_pieces.y] == 2 or ( not ( (pos.x == 6 or pos.x == 0) and (pos.y == 6 or pos.y == 0) ) ):
			return true
	return false
func is_empty(pos: Vector2):
	if not is_valid_position(pos): return false
	else:
		if board[pos.x][pos.y] == 0: return true
		return false
func is_enemy(pos : Vector2):
	if not is_valid_position(pos): return false
	else:
		if white and board[pos.x][pos.y] < 0 or !white and board[pos.x][pos.y] > 0 : return true
		return false


var win = false

func end(winner: int):
	if win == false:
		win = true
		if winner == 1:
			$CanvasLayer/win/Label.text = "White/Player1 WIN!"
			$CanvasLayer/win/Sprite2D.texture = WHITE_KING
			GameManager.PlayerVictory[0] += 1
			$CanvasLayer/win.visible = true
		elif winner == 0:
			$CanvasLayer/win/Label.text = "Black/Player2 WIN!"
			$CanvasLayer/win/Sprite2D.texture = BLACK_PAWN
			GameManager.PlayerVictory[1] += 1
			$CanvasLayer/win.visible = true
		else:
			$CanvasLayer/win/Sprite2D.visible = false
			$CanvasLayer/win/Label.text = "Draw !"
			GameManager.PlayerVictory[0] += 0.5
			GameManager.PlayerVictory[1] += 0.5
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
