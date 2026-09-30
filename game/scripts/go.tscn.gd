extends Control

const BOARD_SIZE = 10
const CELL_WIDTH = 60

const CHESS_TEXTURE = preload("uid://y84bw3qsbxxw")

const MOVES = preload("uid://dgujov8w87o3n")


@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dots

@onready var white_pieces: Control = $CanvasLayer/White_pieces
@onready var black_pieces: Control = $CanvasLayer/Black_pieces

const BLACK_DOT = preload("uid://dbarvyx1hijas")
const WHITE_DOT = preload("uid://ddfclw5gkkt6i")

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
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 1, 0, 0, 0, 0, 0, 0, -1, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, -1, 0, 0, 0, 0, 0, 0, 1, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	else:
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	
	display_board()
	


func display_board():
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = CHESS_TEXTURE.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) - 300, -i * CELL_WIDTH - (CELL_WIDTH / 2) + 300)
			
			if GameManager.Q1 == 3:
				holder.texture = MOVES
				holder.modulate = Color(1.0, 1.0, 1.0, 0.0)
			match board[abs(i-9)][j]:
				-1 : holder.texture = BLACK_DOT
				0 : holder.texture = null
				1 : holder.texture = WHITE_DOT
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
			var var1 = (snapped(get_global_mouse_position().x + 360,0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 360,0) / CELL_WIDTH) - 1

			set_move(var2,var1)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_mouse_out()
			if is_mouse_out() == false: return
			var var1 = (snapped(get_global_mouse_position().x + 360,0) / CELL_WIDTH) - 1
			var var2 = (snapped(get_global_mouse_position().y + 360,0) / CELL_WIDTH) - 1
			
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
			child.global_position = Vector2(drawing[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 300,(abs(drawing[i].x-9)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 300)


func is_mouse_out():
	if get_global_mouse_position().x < 300 and get_global_mouse_position().x > -300 and get_global_mouse_position().y > -300 and get_global_mouse_position(). y < 300 : return true
	return false

func show_options():
	var all = true
	
	moves = []
	for i in 10:
		for j in 10:
			if board[i][j] == 0:
				if not can_be_captured(Vector2(i,j),[],Vector2(i,j)):
					moves += [Vector2(i,j)]
				else:
					var directions = [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
					for dirs in directions:
						if can_capture(Vector2(i,j)+dirs,[],Vector2(i,j)):
							moves += [Vector2(i,j)]
					
			elif (board[i][j] == -1 and white) or (board[i][j] == 1 and !white):
				all = false
	show_dots()
	if moves == []:
		if all == true:
			if white:
				end(0)
			else:
				end(1)
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
		holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH/2) - 300,(abs(i.x-9)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 300)
		holder.modulate = 'ffffff64'
		holder.scale = Vector2(3,3)

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var2,var1):
	
	delete_dots()
	for i in moves:
		if i.x == var2 and i.y == var1:
			
			
			
			if white:
				board[var2][var1] = -1
			else:
				board[var2][var1] = 1
			
			var directions = [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
			for k in directions.size():
				if is_valid_position(Vector2(var2,var1)+directions[k]) and not is_enemy(Vector2(var2,var1)+directions[k]):
					if can_capture(Vector2(var2,var1)+directions[k],[],Vector2(-10,-10)):
						capture(Vector2(var2,var1)+directions[k])
			
			
			
			drawing = []
			for child in $move.get_children():
				child.queue_free()
			
			var _1 = CHESS_TEXTURE.instantiate()
			$move.add_child(_1)
			_1.texture = MOVES
			_1.modulate = Color(0.776, 0.443, 1.0, 0.784)
			_1.global_position = Vector2(var1 * CELL_WIDTH + (CELL_WIDTH/2) - 300,(abs(var2-9)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 300)
			
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

func can_capture(piece_pos,none,valid):
	var direction = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	
	var pos = Vector2()
	var need = 0
	var has = 0
	
	var test = []
	
	if is_valid_position(piece_pos) and not is_empty(piece_pos) and not is_enemy(piece_pos):
		for i in direction:
			pos = piece_pos
			pos += i
			while is_valid_position(pos) and not is_empty(pos) and not is_enemy(pos) and not none.has(pos):
				none += [pos]
				
				for j in direction:
					var other_pos = pos
					other_pos += j
					if is_valid_position(other_pos) and not is_empty(other_pos) and not is_enemy(other_pos) and not none.has(other_pos):
						need += 1
						if ((not is_empty(other_pos)) or not is_valid_position(other_pos)) or valid == pos:
							has += 1
						test += [Vector2(other_pos.x,other_pos.y)]
					else:
						need += 1
						if ((not is_empty(other_pos)) or not is_valid_position(other_pos)) or valid == pos:
							has += 1
				
				pos += i
			need += 1
			if ((not is_empty(pos)) or not is_valid_position(pos)) or valid == pos:
				has += 1
		
		if need == has:
			if test.size() > 0:
				for i in test.size():
					need += 1
					if can_capture(test[i],none,valid):
						has += 1
	
	if need == has and need > 1:
		return true
	
	return false

func can_be_captured(piece_pos,none,valid):
	var direction = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	
	var pos = Vector2()
	var need = 0
	var has = 0
	
	var test = []
	
	if is_valid_position(piece_pos) and is_empty(piece_pos):
		for i in direction:
			pos = piece_pos
			pos += i
			while is_valid_position(pos) and not is_empty(pos) and is_enemy(pos) and not none.has(pos):
				none += [pos]
				
				for j in direction:
					var other_pos = pos
					other_pos += j
					if is_valid_position(other_pos) and not is_empty(other_pos) and is_enemy(other_pos) and not none.has(other_pos):
						need += 1
						if ((not is_empty(pos)) or not is_valid_position(pos)) or valid == pos:
							has += 1
						test += [Vector2(other_pos.x,other_pos.y)]
					else:
						need += 1
						if ((not is_empty(pos)) or not is_valid_position(pos)) or valid == pos:
							has += 1
				
				pos += i
			need += 1
			if ((not is_empty(pos)) or not is_valid_position(pos)) or valid == pos:
				has += 1
		
		if need == has:
			if test.size() > 0:
				for i in test.size():
					need += 1
					if can_be_captured(test[i],none,valid):
						has += 1
		
		if need == has and need > 1:
			return true
		
	return false

func capture(piece_pos):
	var direction = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	
	var pos = Vector2()
	
	var test = []
	
	
	for i in direction:
		pos = piece_pos
		pos += i
		while is_valid_position(pos) and not is_empty(pos) and not is_enemy(pos):
			
			board[pos.x][pos.y] = 0
			
			for j in direction:
				var other_pos = pos
				other_pos += j
				if is_valid_position(other_pos) and not is_empty(other_pos) and not is_enemy(other_pos):
					test += [Vector2(other_pos.x,other_pos.y)]
			
			pos += i
	board[piece_pos.x][piece_pos.y] = 0
	
	if test.size() > 0:
		for i in test.size():
			capture(test[i])
	


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
			$CanvasLayer/win/Label.text = "White/Player1 WIN!"
			$CanvasLayer/win/Sprite2D.texture = WHITE_DOT
			GameManager.PlayerVictory[0] += 1
			$CanvasLayer/win.visible = true
		elif winner == 1:
			$CanvasLayer/win/Label.text = "Black/Player2 WIN!"
			$CanvasLayer/win/Sprite2D.texture = BLACK_DOT
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
