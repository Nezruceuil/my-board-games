extends Control

const BOARD_SIZE = 9
const CELL_WIDTH = 60

const CHESS_TEXTURE = preload("uid://y84bw3qsbxxw")

const MOVES = preload("uid://dgujov8w87o3n")


const CASTLE_BLUE_PEASANT = preload("uid://cu8hwcdi2lqy8")
const CASTLE_BLUE_ARCHER = preload("uid://b8c1bshh5j4dt")
const CASTLE_BLUE_GUNNER = preload("uid://bgajqhuq2eoe")
const CASTLE_BLUE_KING = preload("uid://wwwyj18cy4ky")
const CASTLE_BLUE_KNIGHT = preload("uid://bv0dq6v6ht64x")
const CASTLE_BLUE_SOLDIER = preload("uid://d4aytygpi1tmv")
const CASTLE_RED_ARCHER = preload("uid://cc2nukdns1pdf")
const CASTLE_RED_GUNNER = preload("uid://x1lub5uo3587")
const CASTLE_RED_KING = preload("uid://vgbxlclfh7po")
const CASTLE_RED_KNIGHT = preload("uid://picx4o7s1ydl")
const CASTLE_RED_PEASANT = preload("uid://bqb4fjkgus5rl")
const CASTLE_RED_SOLDIER = preload("uid://4amb8yijuhe7")

const CASTLE_BLUE_WALL = preload("uid://eyicyf1mty3m")
const CASTLE_RED_WALL = preload("uid://dcywc6f8jrhnb")



@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dots

@onready var white_pieces: Control = $CanvasLayer/White_pieces
@onready var black_pieces: Control = $CanvasLayer/Black_pieces


# --- AI setup -----------------------------------------------------------
## Set false for human vs human. When true, whichever side matches
## `ai_side` is played by CastleAi instead of by clicking.
@export var vs_ai: bool = true
## Value of this script's `white` flag that the AI controls. Remember
## `white == true` here means "the side that owns the negative-numbered
## pieces", not literally the white chess pieces - see is_enemy() below.
## Default (true) makes the AI play second, i.e. Player 2 / "P2 turn".
@export var ai_side: bool = true

var ai_thinking: bool = false
# --------------------------------------------------------------------


# Vars
# -7 = black wall
# -6 = black roi
# -5 = black cavalier
# -4 = black cannonier
# -3 = black archer
# -2 = black soldat
# -1 = black paysan
# 0 = empty
# 7 = white wall
# 6 = white roi
# 5 = white cavalier
# 4 = white cannonier
# 3 = white archer
# 2 = white soldat
# 1 = white paysan

var position_history: Dictionary = {}

var board : Array
var white : bool = false
var state : bool = false
var moves = []
var selected_pieces : Vector2

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
	if GameManager.Bots_difficulty == true: CastleAi.time_budget_ms = 8000
	else: CastleAi.time_budget_ms = 1000
	
	if GameManager.Q2 == 1: time = Vector2(60,60)
	elif GameManager.Q2 == 3: time = Vector2(300,300)
	else: $CanvasLayer/Timer.visible = false
	
	if GameManager.Q1 == 1:
		board.append([0, -5, -4, -3, -6, -3, -4, -5, 0])
		board.append([0, -1, -2, -7, -3, -7, -2, -1, 0])
		board.append([0, 0, 0, -1, -2, -1, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 1, 2, 1, 0, 0, 0])
		board.append([0, 1, 2, 7, 3, 7, 2, 1, 0])
		board.append([0, 5, 4, 3, 6, 3, 4, 5, 0])
	else:
		board.append([-5, -4, -5, -3, -6, -3, -5, -4, -5])
		board.append([-7, -2, -7, -1, -1, -1, -7, -2, -7])
		board.append([-1, 0, -1, -7, -2, -7, -1, 0, -1])
		board.append([0, 0, 0, -1, 0, -1, 0, 0, 0])
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0])
		board.append([0, 0, 0, 1, 0, 1, 0, 0, 0])
		board.append([1, 0, 1, 7, 2, 7, 1, 0, 1])
		board.append([7, 2, 7, 1, 1, 1, 7, 2, 7])
		board.append([5, 4, 5, 3, 6, 3, 5, 4, 5])
	
	
	display_board()
	
	if GameManager.Bots == 3 or GameManager.Bots == 1:
		_do_ai_turn()


func display_board():
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = CHESS_TEXTURE.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) - 270, -i * CELL_WIDTH - (CELL_WIDTH / 2) + 270)
			if white: holder.rotation_degrees = 180
			
			match board[abs(i-8)][j]:
				-7 : holder.texture = CASTLE_BLUE_WALL
				-6 : holder.texture = CASTLE_BLUE_KING
				-5 : holder.texture = CASTLE_BLUE_KNIGHT
				-4 : holder.texture = CASTLE_BLUE_GUNNER
				-3 : holder.texture = CASTLE_BLUE_ARCHER
				-2 : holder.texture = CASTLE_BLUE_SOLDIER
				-1 : holder.texture = CASTLE_BLUE_PEASANT
				0 : holder.texture = null
				7 : holder.texture = CASTLE_RED_WALL
				6 : holder.texture = CASTLE_RED_KING
				5 : holder.texture = CASTLE_RED_KNIGHT
				4 : holder.texture = CASTLE_RED_GUNNER
				3 : holder.texture = CASTLE_RED_ARCHER
				2 : holder.texture = CASTLE_RED_SOLDIER
				1 : holder.texture = CASTLE_RED_PEASANT
	
	if white:
		$CanvasLayer/Label.text = "P2 turn"
		$Camera2D.rotation_degrees = 180
	else:
		$CanvasLayer/Label.text = "P1 turn"
		$Camera2D.rotation_degrees = 0




func _input(event: InputEvent) -> void:
	if ai_thinking: return
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
					
					const ARROWS_2 = preload("uid://ccoticpruvb84")
					const ARROWS_1 = preload("uid://d2seayohxq2ln")
					
					var dx = _var1 - var1
					var dy = _var2 - var2
					var length = sqrt(pow(dx, 2) + pow(dy, 2))
					var dir = atan2(dy, dx)

					show_arrows(null,null,null,null)
					show_drawing(null,null)
					if is_valid_position(Vector2(_var2, _var1)):
						if Vector2(var2, var1) == Vector2(_var2, _var1):
							var child = CHESS_TEXTURE.instantiate()
							$move.add_child(child)
							child.texture = MOVES
							child.modulate = GameManager.color
							child.global_position = Vector2(var1 * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(var2-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)
						else:
							var child = CHESS_TEXTURE.instantiate()
							$arrows.add_child(child)
							child.texture = ARROWS_1
							child.scale = Vector2(3.5*length,3.5)
							child.modulate = GameManager.color
							child.global_position = Vector2(var1 * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(var2-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)
							child.rotation = dir
							child.move_local_x(abs(length - 8))
							
							var child2 = CHESS_TEXTURE.instantiate()
							$arrows.add_child(child2)
							child2.texture = ARROWS_2
							child2.modulate = GameManager.color
							child2.rotation = dir
							child2.global_position = Vector2(var1 * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(var2-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)
							child2.move_local_x(length * CELL_WIDTH + 16)
					
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
	if not x == null:
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
			child.move_local_x(abs(arrows[i].w - 8))
			
			var child2 = CHESS_TEXTURE.instantiate()
			$arrows.add_child(child2)
			child2.texture = ARROWS_2
			child2.modulate = GameManager.color
			child2.rotation = arrows[i].z
			child2.global_position = Vector2(arrows[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(arrows[i].x-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)
			child2.move_local_x(arrows[i].w * CELL_WIDTH + 16)


func show_drawing(x,y):
	if not x == null:
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
			
			var cavalry = false
			if not board[var2+((selected_pieces.x-var2)*0.5)][var1+((selected_pieces.y-var1)*0.5)] == 0 and abs(board[selected_pieces.x][selected_pieces.y]) == 5:
				board[var2][var1] = board[selected_pieces.x][selected_pieces.y]
				
				if (board[var2+((selected_pieces.x-var2)*0.5)][var1+((selected_pieces.y-var1)*0.5)] > 0 and white) or (board[var2+((selected_pieces.x-var2)*0.5)][var1+((selected_pieces.y-var1)*0.5)] < 0 and !white):
					if (not board[round(var2+((selected_pieces.x-var2)*0.5)+0.2)][round(var1+((selected_pieces.y-var1)*0.5)+0.2)] == 0) and (not board[round(var2+((selected_pieces.x-var2)*0.5)-0.2)][round(var1+((selected_pieces.y-var1)*0.5)-0.2)] == 0):
						cavalry = true
					if (abs(board[round(var2+((selected_pieces.x-var2)*0.5)+0.2)][round(var1+((selected_pieces.y-var1)*0.5)+0.2)]) == 7) or (abs(board[round(var2+((selected_pieces.x-var2)*0.5)-0.2)][round(var1+((selected_pieces.y-var1)*0.5)-0.2)]) == 7):
						if white: end(false)
						else: end(true)
					board[round(var2+((selected_pieces.x-var2)*0.5)+0.2)][round(var1+((selected_pieces.y-var1)*0.5)+0.2)] = 0
					board[round(var2+((selected_pieces.x-var2)*0.5)-0.2)][round(var1+((selected_pieces.y-var1)*0.5)-0.2)] = 0
				
				board[selected_pieces.x][selected_pieces.y] = 0
			elif board[var2][var1] == 0 or abs(board[selected_pieces.x][selected_pieces.y]) == 2 or abs(board[selected_pieces.x][selected_pieces.y]) == 1:
				if abs(board[selected_pieces.x][selected_pieces.y]) == 1 and ((var2 < 2  and !white) or (var2 > 6 and white)):
					board[var2][var1] = 2
				else:
					board[var2][var1] = board[selected_pieces.x][selected_pieces.y]
				board[selected_pieces.x][selected_pieces.y] = 0
			else:
				if (board[var2][var1] > 0 and white) or (board[var2][var1] < 0 and !white):
					board[var2][var1] = 0
			
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
			
			
			var text = ""
			if cavalry == true:
				text = "cavalry on "
			elif board[var2][var1] == 0:
				match abs(board[selected_pieces.x][selected_pieces.y]):
					3: text = "arrow shot on "
					4: text = "bullet shot on "
					5: text = "knight "
					6: text = "king "
					7: text = "hot water drop on "
			else:
				match abs(board[var2][var1]):
					1: text = "paysant "
					2: text = "soldier "
					3: text = "archer "
					4: text = "gunner "
					5: text = "knight "
					6: text = "king "
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
	
	if GameManager.Bots == 3:
		_do_ai_turn()
	else:
		if GameManager.Bots == 1 and !white:
			_do_ai_turn()
		elif GameManager.Bots == 2 and white:
			_do_ai_turn()


## Plays one move for the AI-controlled side. Mirrors the resolution,
## notation, and end-game logic in set_move(), but sources the move from
## CastleAi instead of a mouse click.
func _do_ai_turn() -> void:
	ai_thinking = true
	# Let the human's move finish rendering before we start "thinking".
	await get_tree().process_frame

	var move: Dictionary = CastleAi.get_best_move(board, white)
	if move.is_empty():
		ai_thinking = false
		return

	var from: Vector2 = move.from
	var to: Vector2 = move.to

	if white and board[to.x][to.y] == 6: end(false)
	elif !white and board[to.x][to.y] == -6: end(true)

	CastleAi.apply_move(board, from, to, white)

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
	_1.global_position = Vector2(from.y * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(from.x-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)

	var _2 = CHESS_TEXTURE.instantiate()
	$move.add_child(_2)
	_2.texture = MOVES
	_2.modulate = Color(0.776, 0.443, 1.0, 0.588)
	_2.global_position = Vector2(to.y * CELL_WIDTH + (CELL_WIDTH/2) - 270,(abs(to.x-8)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 270)

	white = !white
	display_board()

	var text = ""
	match abs(board[to.x][to.y]):
		1: text = "paysant "
		2: text = "soldier "
		3: text = "archer "
		4: text = "knight "
		5: text = "gunner "
		6: text = "king "
	match int(to.y):
		0: text += "a"
		1: text += "b"
		2: text += "c"
		3: text += "d"
		4: text += "e"
		5: text += "f"
		6: text += "g"
		7: text += "h"
		8: text += "i"
	text += str(round(abs(int(to.x)-9)))
	$CanvasLayer/buttons/chat.text += "
	" + text

	ai_thinking = false


func get_moves():
	var _moves = []
	match abs(board[selected_pieces.x][selected_pieces.y]):
		1: _moves = get_paysan_moves()
		2: _moves = get_soldat_moves()
		3: _moves = get_archer_moves()
		4: _moves = get_canonnier_moves()
		5: _moves = get_cavalier_moves()
		6: _moves = get_soldat_moves()
	
	return _moves


func get_paysan_moves():
	var _moves = []
	var directions = []
	
	if !white: directions = [Vector2(0,1),Vector2(0,-1),Vector2(-1,0)]
	else: directions = [Vector2(0,1),Vector2(0,-1),Vector2(1,0)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
	
	directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1)]
	
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_enemy(pos): _moves.append(pos)
	
	return _moves

func get_soldat_moves():
	var _moves = []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
			elif ((board[pos.x][pos.y] == 7 and !white) or (board[pos.x][pos.y] == -7 and white)) and is_valid_position(pos+i) and is_empty(pos+i):
				_moves.append(pos+i)
	
	return _moves

func get_archer_moves():
	var _moves = []
	var directions = [Vector2(0,1),Vector2(0,-1),Vector2(-1,0),Vector2(1,0)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif ((board[pos.x][pos.y] == 7 and !white) or (board[pos.x][pos.y] == -7 and white)) and is_valid_position(pos+i) and is_empty(pos+i):
				_moves.append(pos+i)
	
	directions = [Vector2(2,-1),Vector2(2,1),Vector2(-1,2),Vector2(1,2),
						Vector2(-2,-1),Vector2(-2,1),Vector2(-1,-2),Vector2(1,-2)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_enemy(pos):
				if not abs(board[pos.x][pos.y])== 7:
					_moves.append(pos)
	
	return _moves

func get_canonnier_moves():
	var _moves = []
	var directions
	
	if white: directions = [Vector2(0,-1),Vector2(0,1),Vector2(1,0)]
	else: directions = [Vector2(0,-1),Vector2(0,1),Vector2(-1,0)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			elif ((board[pos.x][pos.y] == 7 and !white) or (board[pos.x][pos.y] == -7 and white)) and is_valid_position(pos+i) and is_empty(pos+i):
				_moves.append(pos+i)
	
	if !white: directions = [Vector2(-3,-1),Vector2(-3,0),Vector2(-3,1)]
	else: directions = [Vector2(3,-1),Vector2(3,0),Vector2(3,1)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_enemy(pos):
				if not abs(board[pos.x][pos.y])== 7:
					_moves.append(pos)
	
	return _moves

func get_cavalier_moves():
	var _moves = []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos) and is_valid_position(pos+i):
			if (not is_empty(pos)) and is_empty(pos+i): _moves.append(pos+i)
	
	directions = [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos) and is_valid_position(pos+i) and is_valid_position(pos+i+i):
			if (is_enemy(pos)) and (is_enemy(pos+i)) and is_empty(pos+i+i): _moves.append(pos+i+i)
	
	
	return _moves

func is_valid_position(pos : Vector2):
	if pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE: return true
	return false
func is_empty(pos: Vector2):
	if board[pos.x][pos.y] == 0: return true
	if (board[pos.x][pos.y] == 6 and white) or (board[pos.x][pos.y] == -6 and !white): return true
	return false
func is_enemy(pos : Vector2):
	if white and board[pos.x][pos.y] > 0 or !white and board[pos.x][pos.y] < 0 : return true
	return false



func end(winner:bool):
	if winner == true:
		$CanvasLayer/win/Label.text = "Red/Player1 WIN!"
		$CanvasLayer/win/Sprite2D.texture = CASTLE_RED_KING
		GameManager.PlayerVictory[0] += 1
	else:
		$CanvasLayer/win/Label.text = "Blue/Player2 WIN!"
		$CanvasLayer/win/Sprite2D.texture = CASTLE_BLUE_KING
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


func _on_resign_pressed() -> void:
	if white: end(true)
	else: end(false)
