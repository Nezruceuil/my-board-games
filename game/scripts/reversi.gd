extends Control

const BOARD_SIZE = 8
const CELL_WIDTH = 60

const CHESS_TEXTURE = preload("uid://y84bw3qsbxxw")

const MOVES = preload("uid://dgujov8w87o3n")


@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dots

@onready var white_pieces: Control = $CanvasLayer/White_pieces
@onready var black_pieces: Control = $CanvasLayer/Black_pieces

const BLUE_DOT = preload("uid://dvp45t12ehgr3")
const RED_DOT = preload("uid://b84b44pweyn7n")


# Vars
# -1 = black
# 0 = empty
# 1 = white


var board : Array
var white : bool = false
var state : bool = false
var moves = []
var dir = []
var selected_pieces : Vector2


var rng = RandomNumberGenerator.new()

var drawing = []

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
		board.append([1, 1, 0, 0, 0, 0, -1, -1])
		board.append([1, 0, 0, 0, 0, 0, 0, -1])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 1, -1, 0, 0, 0])
		board.append([0, 0, 0, -1, 1, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([-1, 0, 0, 0, 0, 0, 0, 1])
		board.append([-1, -1, 0, 0, 0, 0, 1, 1])
	else:
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 1, -1, 0, 0, 0])
		board.append([0, 0, 0, -1, 1, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0])
	
	display_board()
	


func display_board():
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = CHESS_TEXTURE.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) - 240, -i * CELL_WIDTH - (CELL_WIDTH / 2) + 240)
			
			if GameManager.Q1 == 3:
				holder.texture = MOVES
				holder.modulate = Color(1.0, 1.0, 1.0, 0.0)
			match board[abs(i-7)][j]:
				-1 : holder.texture = BLUE_DOT
				0 : holder.texture = null
				1 : holder.texture = RED_DOT
	
	if white:
		$CanvasLayer/Label.text = "P2 turn"
	else:
		$CanvasLayer/Label.text = "P1 turn"
	
	show_options()


func _input(event: InputEvent) -> void:
	if event.is_action("Delete"):
		drawing = []
		for child in $move.get_children():
			child.queue_free()
	elif event is InputEventMouseButton && event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_out()
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 300,0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 300,0) / CELL_WIDTH) - 1

			set_move(var2,var1)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_mouse_out()
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 300,0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 300,0) / CELL_WIDTH) - 1
			
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
			child.global_position = Vector2(drawing[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(drawing[i].x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)


func is_mouse_out():
	if get_global_mouse_position().x < 240 and get_global_mouse_position().x > -240 and get_global_mouse_position().y > -240 and get_global_mouse_position(). y < 240 : return true
	return false

func show_options():
	var has = true
	var all = true
	
	moves = []
	for i in 8:
		for j in 8:
			if (board[i][j] == -1 and white) or (board[i][j] == 1 and !white):
				all = false
				selected_pieces = Vector2(i,j)
				moves += get_moves()
				if moves == []:
					state = false
			elif board[i][j] == 0:
				has = false
	show_dots()
	if moves == []:
		if all == true:
			if white:
				end(0)
			else:
				end(1)
		if has == false:
			white = !white
		else:
			var total = Vector2(0,0)
			for i in 8:
				for j in 8:
					if board[i][j] == 1: total.x += 1
					elif board[i][j] == -1: total.y += 1
			if total.x == total.y:
				end(2)
			else:
				if total.x > total.y:
					end(0)
				else:
					end(1)

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
			
			
			
			var selected_piece = selected_pieces
			board[var2][var1] = board[selected_pieces.x][selected_pieces.y]
			selected_pieces = i
			
			var dir = get_other_moves()
			
			selected_pieces = selected_piece
			
			
			var pos = Vector2()
			
			for k in dir.size():
				pos = Vector2(var2,var1)
				while (not (((board[pos.x][pos.y] == -1 and white and not pos == Vector2(var2,var1)) or (board[pos.x][pos.y] == 1 and !white and not pos == Vector2(var2,var1))))) and is_valid_position(pos):
					board[pos.x][pos.y] = board[selected_pieces.x][selected_pieces.y]
					pos += dir[k]
			
			
			drawing = []
			for child in $move.get_children():
				child.queue_free()
			
			var _1 = CHESS_TEXTURE.instantiate()
			$move.add_child(_1)
			_1.texture = MOVES
			_1.modulate = Color(0.776, 0.443, 1.0, 0.784)
			_1.global_position = Vector2(var1 * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(var2-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
			
			white = !white
			display_board()
			
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
	show_options()


func get_moves():
	dir = []
	var _moves = []
	var pos = Vector2()
	var direction = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	for i in direction.size():
		pos = Vector2(selected_pieces.x,selected_pieces.y) + direction[i]
		if is_valid_position(pos):
			if (not is_enemy(pos)) and (not is_empty(pos)):
				while is_valid_position(pos) and (not is_enemy(pos)) and (not is_empty(pos)):
					pos += direction[i]
				pos -= direction[i]
				if is_valid_position(pos):
					if not is_enemy(pos) and not is_empty(pos) and is_empty(pos + direction[i]):
						pos += direction[i]
						if not moves.has(pos):
							_moves.append(pos)
							dir.append(direction[i])
	
	return _moves

func get_other_moves():
	var _moves = []
	var pos = Vector2()
	var direction = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	for i in direction.size():
		pos = Vector2(selected_pieces.x,selected_pieces.y) + direction[i]
		if is_valid_position(pos):
			if (not is_enemy(pos)) and (not is_empty(pos)):
				while is_valid_position(pos) and (not is_enemy(pos)) and (not is_empty(pos)):
					pos += direction[i]
				pos -= direction[i]
				if is_valid_position(pos):
					if not is_enemy(pos) and not is_empty(pos) and is_enemy(pos + direction[i]):
						pos += direction[i]
						_moves.append(direction[i])
	
	return _moves


func is_valid_position(pos : Vector2):
	if pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE: return true
	return false
func is_empty(pos: Vector2):
	if not is_valid_position(pos): return false
	else:
		if board[pos.x][pos.y] == 0: return true
		return false
func is_enemy(pos : Vector2):
	if not is_valid_position(pos): return false
	else:
		if white and board[pos.x][pos.y] == -1 or !white and board[pos.x][pos.y] == 1 : return true
		return false


var win = false

func end(winner: int):
	if win == false:
		win = true
		if winner == 0:
			$CanvasLayer/win/Label.text = "Red/Player1 WIN!"
			$CanvasLayer/win/Sprite2D.texture = RED_DOT
			GameManager.PlayerVictory[0] += 1
			$CanvasLayer/win.visible = true
		elif winner == 1:
			$CanvasLayer/win/Label.text = "Blue/Player2 WIN!"
			$CanvasLayer/win/Sprite2D.texture = BLUE_DOT
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
