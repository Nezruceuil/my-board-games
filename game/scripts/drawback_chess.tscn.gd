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

# Drawback
var drawback = Vector2(0,0)
var drawback_text = {
					"0"="If you lose your queen you lose the game!",
					"1"="You cannot eat until the 10th move!",
					"2"="You cannot move the same piece twice in a row.",
					"3"="Only pawns can eat pawns!",
					"4"="Pawns cannot capture!",
					"5"='Pawns cannot do "en_passant"',
					"6"="Pawns cannot move 2 tile forward",
					"7"="The king cannot move!",
					"8"="The queen is actually a rook",
					"9"="The queen is actually a bishop",
					"10"="The queen is actually a knight",
					"11"="You cannot castle",
					"12"="Your first 3 moves cannot be a pawn move.",
					"13"="Your king cannot capture.",
					"14"="Every fifth move must be a king move.",
					"15"="Pawns capture in the wrong way!",
					"16"="Pawns only capture straight ahead.",
					"17"="every turn a random piece is unplayable",
					"18"="You pawns will never promote!",
					"19"="When the king move it must eat its own pieces if it can.",
					"20"="When a pawn hasn't move it must move 2 tiles forward!",
					"21"="Pieces refuse to eat their own kind!",
					"22"="You must change the selected piece square color every turn!",
					"23"="You cannot move to the center except to eat the king",
					"24"="Pawns refuse to move on pair turn",
					"25"="You cannot have two pawns on the same file!",
					"26"="You cannot have two rooks on the same file!",
					"27"="You cannot have two bishops on the same file!",
					"28"="You cannot have two knights on the same file!",
					"29"="If you move a piece next to another piece of the same type, your piece die.",
					"30"="Pawns promote to a random piece.",
					"31"="Every file Must have at least one piece in it or you lose instantly!",
					"32"="Rooks move only in front of them.",
					"33"="Pieces that are not pawns promote to a pawn if they move to the last rank.",
					"34"="Every time you move a Piece that is not the king it has a 10% chance to die!",
					"35"="Every 10 turns the piece you move dies.",
					"36"="If a piece land on the ",
					"37"="You do not see what piece is what.",
					"38"="The board orientation is random, You can't see your move options and the board.",
					"39"="You cannot go on the file of you opponent king!",
					"40"="You cannot move your n piece where n += 1 every turn",
					"41"="Every capture create fog that is placed on the captured square!",
					"42"="Every turn a black fog appears on a random square!",
					"43"="You have the same drawback than your opponent!",
					"44"="Your opponent queen is a Necromancer! She do not capture pieces, she change their side!",
					"45"="You can only capture on pair turn!",
					"46"="You can only capture on unpair turn!",
					"47"="Your Knights are fishes they move one square at a time on any diagonals.",
					"48"="Your king need to have 4 piece next to him or you lose!",
					"49"="You must swap playing kingside and queenside."
					}

var drawback_challenge = [Vector2(-1,-1),Vector2(-1,-1)]

var drawback_challenge_list = [[],[]]

var same = [false,false]

var move = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	drawback = Vector2(int(rng.randi_range(0,49)),int(rng.randi_range(0,49)))
	
	#drawback = Vector2(49,40)
	
	
	if drawback.x == 44: drawback_challenge_list[0] = false
	if drawback.y == 44: drawback_challenge_list[1] = false
	
	if drawback.y == 36: drawback_challenge[1] = Vector2(rng.randi_range(0,7),rng.randi_range(0,7))
	
	if drawback.x == 36:
		drawback_challenge[0] = Vector2(rng.randi_range(0,7),rng.randi_range(0,7))
		
		var drawback_num = ""
		match drawback_challenge[0].x:
			0.0: drawback_num = "a"
			1.0: drawback_num = "b"
			2.0: drawback_num = "c"
			3.0: drawback_num = "d"
			4.0: drawback_num = "e"
			5.0: drawback_num = "f"
			6.0: drawback_num = "g"
			7.0: drawback_num = "h"
		
		$CanvasLayer/drawback.text = str(drawback_text["36"] + drawback_num + str(int(drawback_challenge[0].y+1)) + " square you lose! (the first 5 moves does not count)")
	else:
		$CanvasLayer/drawback.text = drawback_text[str(int(drawback.x))]
	
	if drawback.x == 43:
		same[0] = true
		drawback.x = drawback.y
	if drawback.y == 43:
		same[1] = true
		drawback.y = drawback.x
	
	
	if GameManager.Q2 == 1: time = Vector2(300,300)
	elif GameManager.Q2 == 3: time = Vector2(600,600)
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


func display_board():
	
	for child in pieces.get_children():
		child.queue_free()
	
	var number = 0
	if ((white and drawback.y == 17) or(!white and drawback.x == 17)):
		if white: drawback_challenge[0] = Vector2(-1,-1)
		else: drawback_challenge[1] = Vector2(-1,-1)
	
	var dir
	if (!white and drawback.x == 38) or (white and drawback.y == 38): dir = rng.randi_range(1,4) * 90
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = CHESS_TEXTURE.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH / 2) - 240, -i * CELL_WIDTH - (CELL_WIDTH / 2) + 240)
			
			if (!white and drawback.x == 38) or (white and drawback.y == 38):
				holder.rotation_degrees = dir
			else:
				if white: holder.rotation_degrees = 180
			
			if (!white and drawback.x == 37) or (white and drawback.y == 37):
				if board[abs(i-7)][j] == 0: holder.texture = null
				else:
					match rng.randi_range(-6,5):
						-6 : holder.texture = BLACK_KING
						-5 : holder.texture = BLACK_QUEEN
						-4 : holder.texture = BLACK_ROOK
						-3 : holder.texture = BLACK_BISHOP
						-2 : holder.texture = BLACK_KNIGHT
						-1 : holder.texture = BLACK_PAWN
						0 : holder.texture = WHITE_KING
						5 : holder.texture = WHITE_QUEEN
						4 : holder.texture = WHITE_ROOK
						3 : holder.texture = WHITE_BISHOP
						2 : holder.texture = WHITE_KNIGHT
						1 : holder.texture = WHITE_PAWN
			else:
				if GameManager.Q1 == 3:
					holder.texture = MOVES
					holder.modulate = Color(1.0, 1.0, 1.0, 0.0)
				else:
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
			
			if ((white and drawback.y == 17 and board[abs(i-7)][j] > 0) or(!white and drawback.x == 17 and board[abs(i-7)][j] > 0)):
				number += 1
	if ((white and drawback.y == 17) or(!white and drawback.x == 17)):
		for i in BOARD_SIZE:
			for j in BOARD_SIZE:
				if not number == -1:
					if ((white and drawback.y == 17 and board[abs(i-7)][j] < 0) or(!white and drawback.x == 17 and board[abs(i-7)][j] > 0)):
						number -= 1
						if rng.randi_range(1,number) == 1:
							if white: drawback_challenge[1] = Vector2(abs(i-7),j)
							else: drawback_challenge[0] = Vector2(abs(i-7),j)
							
							var _3 = CHESS_TEXTURE.instantiate()
							$move.add_child(_3)
							_3.texture = MOVES
							_3.modulate = Color(0.898, 0.0, 0.0, 1.0)
							_3.global_position = Vector2(j * CELL_WIDTH + (CELL_WIDTH/2) - 240,(i*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
							
							number = -1
	
	if (!white and drawback.x == 40) or (white and drawback.y == 40):
		var num = 1
		for i in 8:
			for j in 8:
				if (white and board[abs(i-7)][j] < 0) or (!white and board[abs(i-7)][j] > 0):
					num += 1
		
		var _pos = ((round(move/2)) % num) + 1
		
		if white: _pos = abs(_pos-num)
		
		num = 0
		for i in 8:
			for j in 8:
				if (white and board[abs(i-7)][j] < 0) or (!white and board[abs(i-7)][j] > 0):
					num += 1
					if num == _pos:
						if white: drawback_challenge[1] = Vector2(abs(i-7),j)
						else: drawback_challenge[0] = Vector2(abs(i-7),j)
						break
		
		var _3 = CHESS_TEXTURE.instantiate()
		$move.add_child(_3)
		_3.texture = MOVES
		_3.modulate = Color(0.898, 0.0, 0.0, 1.0)
		if !white: _3.global_position = Vector2(drawback_challenge[0].y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(drawback_challenge[0].x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
		else: _3.global_position = Vector2(drawback_challenge[1].y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(drawback_challenge[1].x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
	
	for i in $up.get_children():
		i.queue_free()
	$CanvasLayer/buttons/chat.visible = true
	if ((!white and drawback.x == 41) or (white and drawback.y == 41)) or ((!white and drawback.x == 42) or (white and drawback.y == 42)):
		$CanvasLayer/buttons/chat.visible = false
		if !white:
			for i in drawback_challenge_list[0]:
				for j in 3:
					var _fog = CHESS_TEXTURE.instantiate()
					$up.add_child(_fog)
					_fog.texture = MOVES
					_fog.modulate = Color(0.0, 0.0, 0.0, 1.0)
					_fog.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(i.x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
					_fog.scale = Vector2(rng.randf_range(3.7,4.2),rng.randf_range(3.7,4.2))
		else:
			for i in drawback_challenge_list[1]:
				for j in 3:
					var _fog = CHESS_TEXTURE.instantiate()
					$up.add_child(_fog)
					_fog.texture = MOVES
					_fog.modulate = Color(0.0, 0.0, 0.0, 1.0)
					_fog.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(i.x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
					_fog.scale = Vector2(rng.randf_range(3.7,4.2),rng.randf_range(3.7,4.2))
	
	if white:
		$CanvasLayer/Label.text = "P2 turn"
		$Camera2D.rotation_degrees = 180
		if drawback.y == 36:
			
			var drawback_num = ""
			match drawback_challenge[1].x:
				0.0: drawback_num = "a"
				1.0: drawback_num = "b"
				2.0: drawback_num = "c"
				3.0: drawback_num = "d"
				4.0: drawback_num = "e"
				5.0: drawback_num = "f"
				6.0: drawback_num = "g"
				7.0: drawback_num = "h"
			
			$CanvasLayer/drawback.text = str(drawback_text["36"] + drawback_num + str(int(drawback_challenge[1].y+1)) + " square you lose! (the first 5 moves does not count)")
		else:
			if (!white and same[0] == true) or (white and same[1] == true):
				$CanvasLayer/drawback.text = drawback_text[str(int(43))]
			else: $CanvasLayer/drawback.text = drawback_text[str(int(drawback.y))]
		
	else:
		$CanvasLayer/Label.text = "P1 turn"
		$Camera2D.rotation_degrees = 0
		if drawback.x == 36:
			
			var drawback_num = ""
			match drawback_challenge[0].x:
				0.0: drawback_num = "a"
				1.0: drawback_num = "b"
				2.0: drawback_num = "c"
				3.0: drawback_num = "d"
				4.0: drawback_num = "e"
				5.0: drawback_num = "f"
				6.0: drawback_num = "g"
				7.0: drawback_num = "h"
			
			$CanvasLayer/drawback.text = str(drawback_text["36"] + drawback_num + str(int(drawback_challenge[0].y+1)) + " square you lose! (the first 5 moves does not count)")
		else:
			if (!white and same[0] == true) or (white and same[1] == true):
				$CanvasLayer/drawback.text = drawback_text[str(int(43))]
			else: $CanvasLayer/drawback.text = drawback_text[str(int(drawback.x))]
	if (!white and drawback.x == 38) or (white and drawback.y == 38):
		$Camera2D.rotation_degrees = dir
		$board.visible = false
	else: $board.visible = true


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
		if not ((!white and drawback.x == 38) or (white and drawback.y == 38)):
			show_dots()

func show_dots():
	var delete = []
	delete_dots()
	if not moves == null:
		for i in moves.size():
			if ((!white and drawback.x == 39) or (white and drawback.y == 39)) and other_piece_in_file(moves[i],-6):
				delete += [i]
			elif ((!white and drawback.x == 49) or (white and drawback.y == 49)) and ((moves[i].y > 3 and int(move*0.5)%2 == 1) or (moves[i].y < 4 and int(move*0.5)%2 == 0)):
				delete += [i]
			else:
				var holder = CHESS_TEXTURE.instantiate()
				dots.add_child(holder)
				holder.texture = MOVES
				holder.global_position = Vector2(moves[i].y * CELL_WIDTH + (CELL_WIDTH/2) - 240,(abs(moves[i].x-7)*-1) * CELL_WIDTH - (CELL_WIDTH/2) + 240)
		for i in delete.size():
			moves.remove_at(delete[i]-i)
			

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var2,var1):
	
	var just_now = false
	delete_dots()
	if not moves == null:
		for i in moves:
			if i.x == var2 and i.y == var1:
				move += 1
				
				if (!white and drawback.x == 41) or (white and drawback.y == 41):
					if (!white and board[var2][var1] < 0) or (white and board[var2][var1] > 0):
						if drawback.x == 41: drawback_challenge_list[0] += [Vector2(var2,var1)]
						if drawback.y == 41: drawback_challenge_list[1] += [Vector2(var2,var1)]
				if (!white and drawback.x == 42) or (white and drawback.y == 42):
					if !white: drawback_challenge_list[0] += [Vector2(rng.randi_range(0,7),rng.randi_range(0,7))]
					else: drawback_challenge_list[1] += [Vector2(rng.randi_range(0,7),rng.randi_range(0,7))]
				
				
				if !white and drawback[0] == 2: drawback_challenge[0] = Vector2(var2,var1)
				if white and drawback[1] == 2: drawback_challenge[1] = Vector2(var2,var1)
				if white and board[var2][var1] == 6: end(false)
				elif !white and board[var2][var1] == -6: end(true)
				if white and drawback.x == 0 or !white and drawback.y == 0:
					if white and board[var2][var1] == 5: end(false)
					if !white and board[var2][var1] == -5: end(true)
				
				
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
						if selected_pieces.x == 0 && selected_pieces.y == 0: white_rook_left = true
						if selected_pieces.x == 0 && selected_pieces.y == 7: white_rook_right = true
					-4:
						if selected_pieces.x == 7 && selected_pieces.y == 0: black_rook_left = true
						if selected_pieces.x == 7 && selected_pieces.y == 7: black_rook_right = true
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
				
				if ((white and drawback.y == 33) or (!white and drawback.x == 33)) and not abs(board[selected_pieces.x][selected_pieces.y]) == 1:
					if board[selected_pieces.x][selected_pieces.y] < 0:
						if i.x == 7: board[selected_pieces.x][selected_pieces.y] = -1
					else:
						if i.x == 0: board[selected_pieces.x][selected_pieces.y] = 1
				
				
				if ((white and drawback.x == 44) or (!white and drawback.y == 44)) and (not board[var2][var1] == 0) and abs(board[selected_pieces.x][selected_pieces.y]) == 5:
					if (white and drawback_challenge_list[0] == false) or (!white and drawback_challenge_list[1] == false):
						board[var2][var1] = -board[var2][var1]
						if white: drawback_challenge_list[0] = true
						else: drawback_challenge_list[1] = true
					else:
						if white: drawback_challenge_list[0] = false
						else: drawback_challenge_list[1] = false
						
						if board[selected_pieces.x][selected_pieces.y] == 6: end(false)
						elif board[selected_pieces.x][selected_pieces.y] == -6: end(true)
						
						board[var2][var1] = board[selected_pieces.x][selected_pieces.y]
						board[selected_pieces.x][selected_pieces.y] = 0
				else:
					if ((white and drawback.y == 29) or(!white and drawback.x == 29)) and piece_next_to(Vector2(var2,var1),-abs(board[selected_pieces.x][selected_pieces.y])):
						board[var2][var1] = 0
					else:
						if ((not ((white and drawback.y == 34) or(!white and drawback.x == 34))) or (not rng.randi_range(1,10) == 1)) or abs(board[selected_pieces.x][selected_pieces.y]) == 6:
							if (not ((white and drawback.y == 35) or (!white and drawback.x == 35))) or not (move%5==0):
								board[var2][var1] = board[selected_pieces.x][selected_pieces.y]
							else:
								if board[selected_pieces.x][selected_pieces.y] == 6: end(false)
								elif board[selected_pieces.x][selected_pieces.y] == -6: end(true)
								board[var2][var1] = 0
						else: board[var2][var1] = 0
					board[selected_pieces.x][selected_pieces.y] = 0
				
				if drawback.y == 31 or drawback.x == 31:
					if not (other_piece_in_file(selected_pieces,1) or other_piece_in_file(selected_pieces,2)or other_piece_in_file(selected_pieces,3) or other_piece_in_file(selected_pieces,4) or other_piece_in_file(selected_pieces,5) or other_piece_in_file(selected_pieces,6)):
						if not (other_piece_in_file(selected_pieces,-1) or other_piece_in_file(selected_pieces,-2)or other_piece_in_file(selected_pieces,-3) or other_piece_in_file(selected_pieces,-4) or other_piece_in_file(selected_pieces,-5) or other_piece_in_file(selected_pieces,-6)):
							if (white and drawback.y == 31) or drawback.x == 31: end(true)
							else: end(false)
				
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
				
				if drawback.x == 36 or drawback.y == 36:
					if move > 5:
						if drawback.x == 36 and drawback_challenge[0] == Vector2(var1,abs(var2-7)):
							if drawback_challenge[0] == drawback_challenge[1]:
								if white: end(false)
								else: end(true)
							else:
								end(false)
						elif drawback.y == 36 and drawback_challenge[1] == Vector2(var1,abs(var2-7)):
							end(true)
				
				var text = ""
				if abs(board[selected_pieces.x][selected_pieces.y]) == 5:
					text = "Schwouch at "
				else:
					match abs(board[var2][var1]):
						0: text = "Boom at "
						2: text = "knight "
						3: text = "bishop "
						4: text = "rook "
						5: text = "queen "
						6: text = "king "
						6: text = "pizza "
				match var1:
					0: text += "a"
					1: text += "b"
					2: text += "c"
					3: text += "d"
					4: text += "e"
					5: text += "f"
					6: text += "g"
					7: text += "h"
				text += str(abs(var2-8))
				$CanvasLayer/buttons/chat.text += "
				" + text
				
				break
	state = false
	king_safety()


func get_moves():
	var _moves = []
	if (((white and drawback.y == 22) or (!white and drawback.x == 22))) and ((int(selected_pieces.x + selected_pieces.y) % 2 == 0 and int(round(move*0.5))%2 == 0) or (not int(selected_pieces.x + selected_pieces.y) % 2 == 0 and not int(round(move*0.5))%2 == 0)):
		return []
	if (not ((white and drawback.y == 14) or (!white and drawback.x == 14))) or abs(board[selected_pieces.x][selected_pieces.y]) == 6 or not ((move+1) % 5 == 0):
		if (not drawback_challenge[0] == selected_pieces and !white) or (not drawback_challenge[1] == selected_pieces and white):
			match abs(board[selected_pieces.x][selected_pieces.y]):
				1: _moves = get_pawn_moves()
				2:
					if (((white and drawback.y == 47) or (!white and drawback.x == 47))):
						_moves = get_fish_moves()
					else:
						_moves = get_knight_moves()
				3: _moves = get_bishop_moves()
				4: _moves = get_rook_moves()
				5: _moves = get_queen_moves()
				6: _moves = get_king_moves()
		return _moves

func get_fish_moves():
	var _moves = []
	var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1)]
	
	for i in directions:
		var pos = selected_pieces + i
		if is_valid_position(pos):
			if is_empty(pos): _moves.append(pos)
			else:
				if is_enemy(pos):
					_moves.append(pos)
	
	return _moves


func get_rook_moves():
	var _moves = []
	
	var directions = []
	if (white and drawback.y == 32) or(!white and drawback.x == 32):
		if white: directions = [Vector2(1,0)]
		else: directions = [Vector2(-1,0)]
	else:
		directions = [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	for i in directions:
		var pos = selected_pieces
		pos += i
		while is_on_board(pos):
			if is_empty(pos):
				if is_valid_position(pos):
					if (not ((white and drawback.y == 26) or(!white and drawback.x == 26))) or other_piece_in_file(pos,4) == false:
						_moves.append(pos)
			elif is_enemy(pos):
				if is_valid_position(pos):
					if (not ((white and drawback.y == 26) or(!white and drawback.x == 26))) or other_piece_in_file(pos,4) == false:
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
			if is_empty(pos):
				if (not ((white and drawback.y == 27) or(!white and drawback.x == 27))) or other_piece_in_file(pos,3) == false:
					_moves.append(pos)
			elif is_enemy(pos):
				if (not ((white and drawback.y == 27) or(!white and drawback.x == 27))) or other_piece_in_file(pos,3) == false:
					_moves.append(pos)
				break
			else: break
			
			pos += i
	
	return _moves

func get_queen_moves():
	var _moves = []
	var directions = []
	
	if ((white and drawback.y == 8) or (!white and drawback.x == 8)):
		directions = [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	elif ((white and drawback.y == 9) or (!white and drawback.x == 9)):
		directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1)]
	elif ((white and drawback.y == 10) or (!white and drawback.x == 10)):
		directions = [Vector2(2,1),Vector2(2,-1),Vector2(1,2),Vector2(-1,2),
						Vector2(-2,1),Vector2(-2,-1),Vector2(1,-2),Vector2(-1,-2)]
	else:
		directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	
	if ((white and drawback.y == 10) or (!white and drawback.x == 10)):
		for i in directions:
			var pos = selected_pieces
			pos += i
			if is_valid_position(pos):
				if is_empty(pos): _moves.append(pos)
				elif is_enemy(pos):
					_moves.append(pos)
	else:
		for i in directions:
			var pos = selected_pieces
			pos += i
			while is_on_board(pos):
				if is_empty(pos):
					if is_valid_position(pos):
						_moves.append(pos)
				elif is_enemy(pos):
					if is_valid_position(pos):
						_moves.append(pos)
					break
				else: break
				
				pos += i
	
	return _moves

func get_king_moves():
	if not ((white and drawback.y == 7) or (!white and drawback.x == 7)):
		var _moves = []
		var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
		
		var can_eat = false
		
		if ((white and drawback.y == 19) or(!white and drawback.x == 19)):
			for i in directions:
				var pos = selected_pieces + i
				if is_valid_position(pos):
					if not is_empty(pos):
						if not is_enemy(pos):
							can_eat = true
		
		for i in directions:
			var pos = selected_pieces + i
			if is_valid_position(pos):
				if not ((white and drawback.y == 19) or (!white and drawback.x == 19)) or can_eat == false:
					if is_empty(pos): _moves.append(pos)
					else:
						if is_enemy(pos):
							_moves.append(pos)
				else:
					if not is_empty(pos):
						if not is_enemy(pos): _moves.append(pos)
		
		
		if not ((white and drawback.y == 11) or (!white and drawback.x == 11)):
			if not ((white and drawback.y == 19) or(!white and drawback.x == 19)) or can_eat == false:
				if white && !black_king:
					if !black_rook_left && is_empty(Vector2(0, 1)) && is_empty(Vector2(0, 2)) && is_empty(Vector2(0, 3)):
						_moves.append(Vector2(0,2))
					if !black_rook_right && is_empty(Vector2(0, 5)) && is_empty(Vector2(0, 6)):
						_moves.append(Vector2(0,6))
				elif !white && !white_king:
					if !white_rook_left && is_empty(Vector2(7, 1)) && is_empty(Vector2(7, 2)) && is_empty(Vector2(7, 3)):
						_moves.append(Vector2(7,2))
					if !white_rook_right && is_empty(Vector2(7, 5)) && is_empty(Vector2(7, 6)):
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
			if is_empty(pos):
				if (not ((white and drawback.y == 28) or(!white and drawback.x == 28))) or other_piece_in_file(pos,2) == false:
					_moves.append(pos)
			elif is_enemy(pos):
				if (not ((white and drawback.y == 28) or(!white and drawback.x == 28))) or other_piece_in_file(pos,2) == false:
					_moves.append(pos)
	
	return _moves

func get_pawn_moves():
	var _moves = []
	if (not ((white and drawback.y == 24) or(!white and drawback.x == 24))) or int(round(move*0.5+0.5))%2 == 0:
		if (not ((white and drawback.y == 12) or(!white and drawback.x == 12))) or move >= 6:
			
			var direction
			var is_first_move = false
			
			if white: direction = Vector2(1, 0)
			else: direction = Vector2(-1, 0)
			
			if !white and selected_pieces.x == 6 or white and selected_pieces.x == 1: is_first_move = true
			
			
			if not ((white and drawback.y == 5) or(!white and drawback.x == 5)):
				if en_passant != null && (white && selected_pieces.x == 4 or !white && selected_pieces.x == 3) && abs(en_passant.y - selected_pieces.y) == 1:
					if (not ((white and drawback.y == 25) or(!white and drawback.x == 25))) or other_piece_in_file(en_passant + direction, 1) == false:
						_moves.append(en_passant + direction)
			
			var pos = selected_pieces + direction
			if not ((white and drawback.y == 20) or (!white and drawback.x == 20)) or !is_first_move:
				if is_valid_position(pos) and is_empty(pos): _moves.append(pos)
				
				if not ((white and drawback.y == 4) or (!white and drawback.x == 4)):
					if ((white and drawback.y == 15) or(!white and drawback.x == 15)):
						pos = selected_pieces + Vector2(direction.x * -1, 1)
						if is_valid_position(pos):
							if is_enemy(pos): _moves.append(pos)
						pos = selected_pieces + Vector2(direction.x * -1 , -1)
						if is_valid_position(pos):
							if is_enemy(pos): _moves.append(pos)
					elif ((white and drawback.y == 16) or(!white and drawback.x == 16)):
						pos = selected_pieces + Vector2(direction.x, 0)
						if is_valid_position(pos):
							if is_enemy(pos): _moves.append(pos)
					else:
						pos = selected_pieces + Vector2(direction.x, 1)
						if is_valid_position(pos):
							if is_enemy(pos):
								if (not ((white and drawback.y == 25) or(!white and drawback.x == 25))) or other_piece_in_file(pos,1) == false:
									_moves.append(pos)
						pos = selected_pieces + Vector2(direction.x, -1)
						if is_valid_position(pos):
							if is_enemy(pos):
								if (not ((white and drawback.y == 25) or(!white and drawback.x == 25))) or other_piece_in_file(pos,1) == false:
									_moves.append(pos)
			
			pos = selected_pieces + direction * 2
			if not ((white and drawback.y == 6) or(!white and drawback.x == 6)):
				if is_first_move and is_empty(pos) and is_valid_position(pos) and is_empty(selected_pieces + direction): _moves.append(pos)
			
	return _moves

func piece_next_to(pos : Vector2, piece : int):
	var _moves = []
	var directions = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	
	
	for i in directions:
		var _pos = pos
		_pos += i
		if is_valid_position(_pos):
			if not _pos == selected_pieces:
				if (!white and board[_pos.x][_pos.y] == piece) or (white and board[_pos.x][_pos.y] == -piece):
					return true
		else: break
	
	return false

func other_piece_in_file(pos : Vector2, piece : int):
	var _moves = []
	var directions = [Vector2(1,0),Vector2(-1,0)]
	
	
	for i in directions:
		var _pos = pos
		_pos += i
		while is_on_board(_pos):
			if _pos.x >= 0 and _pos.x < BOARD_SIZE and _pos.y >= 0 and _pos.y < BOARD_SIZE:
				if not _pos == selected_pieces:
					if (!white and board[_pos.x][_pos.y] == piece) or (white and board[_pos.x][_pos.y] == -piece):
						return true
			else: break
			
			_pos += i
	
	return false

func is_on_board(pos : Vector2):
	if pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE: return true
	return false
func is_valid_position(pos : Vector2):
	if pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE:
		if (((white and drawback.y == 23) or (!white and drawback.x == 23))):
			if not ((pos.x == 3 or pos.x == 4) and (pos.y == 3 or pos.y == 4)) or abs(board[pos.x][pos.y]) == 6: return true
		else: return true
	return false
func is_empty(pos: Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false
func is_enemy(pos : Vector2):
	if (((white and drawback.y == 45) or (!white and drawback.x == 45))) and int(round(move*0.5)) % 2 == 0:
		return false
	
	if (((white and drawback.y == 46) or (!white and drawback.x == 46))) and int(round(move*0.5)) % 2 == 1:
		return false
	
	if (((white and drawback.y == 21) or (!white and drawback.x == 21))) and abs(board[selected_pieces.x][selected_pieces.y]) == abs(board[pos.x][pos.y]): return false
	else:
		if ((white and drawback.y == 13) or (!white and drawback.x == 13)) and ((!white and board[selected_pieces.x][selected_pieces.y] == 6) or (white and board[selected_pieces.x][selected_pieces.y] == -6)): return false
		if ((white and drawback.y == 1) or (!white and drawback.x == 1)) and move < 20: return false
		else:
			if (not ((white and drawback.y == 3) or (!white and drawback.x == 3))) or (board[selected_pieces.x][selected_pieces.y] == 1 or board[selected_pieces.x][selected_pieces.y] == -1) or not(board[pos.x][pos.y] == 1 or board[pos.x][pos.y] == -1):
				if white and board[pos.x][pos.y] > 0 or !white and board[pos.x][pos.y] < 0 : return true
				else: return false
			else:
				return false

func promote(_var: Vector2):
	if ((white and drawback.y == 30) or(!white and drawback.x == 30)):
		await get_tree().create_timer(0.1).timeout
		promotion_square = _var
		if white: board[promotion_square.x][promotion_square.y]= rng.randi_range(2,5)
		else: board[promotion_square.x][promotion_square.y]= -rng.randi_range(2,5)
		promotion_square = null
		display_board()
	else:
		if not ((white and drawback.y == 18) or (!white and drawback.x == 18)):
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
		$CanvasLayer/win/Sprite2D.texture = WHITE_KING
		GameManager.PlayerVictory[0] += 1
	else:
		$CanvasLayer/win/Label.text = "Black/Player2 WIN!"
		$CanvasLayer/win/Sprite2D.texture = BLACK_KING
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



func king_safety():
	if drawback.x == 48:
		for x in 8:
			for y in 8:
				if board[x][y] == 6:
					var count = 0
					var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
					
					for i in directions:
						var _pos = Vector2(x,y) + i
						if _pos.x >= 0 and _pos.x < 8 and _pos.y >= 0 and _pos.y < 8:
							if  not board[_pos.x][_pos.y] == 0:
								count += 1
					
					if count < 4: end(false)
					break
	if drawback.y == 48:
		for x in 8:
			for y in 8:
				if board[x][y] == -6:
					var count = 0
					var directions = [Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
					
					for i in directions:
						var _pos = Vector2(x,y) + i
						if _pos.x >= 0 and _pos.x < 8 and _pos.y >= 0 and _pos.y < 8:
							if  not board[_pos.x][_pos.y] == 0:
								count += 1
					
					if count < 4: end(true)
					break
