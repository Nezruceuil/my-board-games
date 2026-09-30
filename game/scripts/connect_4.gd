extends Control

var white = true

var board : Array

var time = Vector2(-1,-1)

var points = Vector2(0,0)

var last = Vector2(0,0)

const CHESS_TEXTURE = preload("uid://y84bw3qsbxxw")
const WHITE_DOT = preload("uid://ddfclw5gkkt6i")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.Q2 == 1: time = Vector2(30,30)
	elif GameManager.Q2 == 3: time = Vector2(60,60)
	
	$Win.visible = false
	board.append([0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not time.x == -1:
		if white:
			time.x -= delta
			if time.x <= 0: end(false)
			$Timer.text = str(round(time.x*100)*0.01) + " seconds left"
		else:
			time.y -= delta
			if time.y <= 0: end(false)
			$Timer.text = str(round(time.y*100)*0.01) + " seconds left"

func _display():
	var all = true
	for child in $coins.get_children():
		child.queue_free()
	
	for x in 7:
		for y in 5:
			if board[y][x] == 0: all = false
			else:
				var holder = CHESS_TEXTURE.instantiate()
				$coins.add_child(holder)
				holder.global_position += Vector2(x*100,y*100)
				holder.scale = Vector2(5.8,5.8)
				holder.texture = WHITE_DOT
				if GameManager.Q1 == 3 and not Vector2(y,x) == last: holder.modulate = Color(0.0, 0.0, 0.0, 0.0)
				elif board[y][x] == 1: holder.modulate = Color(0.805, 0.0, 0.0, 1.0)
				else: holder.modulate = Color(0.0, 0.486, 0.799, 1.0)
	if all == true: end(true)
	white = !white
	if white: $Panel.modulate = Color(0.725, 0.0, 0.0)
	else: $Panel.modulate = Color(0.0, 0.384, 1.0)

func coin(x):
	if board[0][x] == 0:
		var pos = -1
		for i in 5:
			if board[i][x] == 0:
				pos += 1
		if white: board[pos][x] = 1
		else: board[pos][x] = -1
		last = Vector2(pos,x)
		win_check(Vector2(pos,x))
		_display()

func win_check(pos):
	var direction = Vector2(0,1)
	var position = Vector2()
	
	var total = 0
	position = pos
	
	# <->
	while is_valid_position(position) and is_mine(position):
		total += 1
		position += direction
	position = pos - direction
	while is_valid_position(position) and is_mine(position):
		total += 1
		position -= direction
	
	if total > 3: end(false)
	
	# \/
	total = 0
	direction = Vector2(1,0)
	position = pos
	while is_valid_position(position) and is_mine(position):
		total += 1
		position += direction
	
	if total > 3: end(false)
	
	# >^
	total = 0
	direction = Vector2(1,1)
	position = pos
	while is_valid_position(position) and is_mine(position):
		total += 1
		position += direction
	position = pos - direction
	while is_valid_position(position) and is_mine(position):
		total += 1
		position -= direction
	if total > 3: end(false)
	
	# ^<
	total = 0
	direction = Vector2(-1,1)
	position = pos
	while is_valid_position(position) and is_mine(position):
		total += 1
		position += direction
	position = pos - direction
	while is_valid_position(position) and is_mine(position):
		total += 1
		position -= direction
	if total > 3: end(false)

func end(draw:bool):
	if draw == true:
		$Win.visible = true
		if GameManager.Q1 == 1 and not points.x == points.y:
			if points.x > points.y:
				Engine.time_scale = 0
				$Win/Label.text = "RED WIN !!!"
				GameManager.PlayerVictory[0] += 1
				await get_tree().create_timer(4).timeout
				get_tree().change_scene_to_file("res://game/menu.tscn")
			else:
				Engine.time_scale = 0
				$Win/Label.text = "BLUE WIN !!!"
				GameManager.PlayerVictory[1] += 1
				await get_tree().create_timer(4).timeout
				get_tree().change_scene_to_file("res://game/menu.tscn")
		else:
			Engine.time_scale = 0
			$Win/Label.text = "DRAW !!!"
			GameManager.PlayerVictory[0] += 0.5
			GameManager.PlayerVictory[1] += 0.5
			await get_tree().create_timer(4).timeout
			get_tree().change_scene_to_file("res://game/menu.tscn")
	else:
		if GameManager.Q1 == 1:
			print(white)
			if white == true: points.x += 1
			else: points.y += 1
		else:
			Engine.time_scale = 0
			$Win.visible = true
			if white:
				$Win/Label.text = "RED WIN !!!"
				GameManager.PlayerVictory[0] += 1
				await get_tree().create_timer(4).timeout
				get_tree().change_scene_to_file("res://game/menu.tscn")
			else:
				$Win/Label.text = "BLUE WIN !!!"
				GameManager.PlayerVictory[1] += 1
				await get_tree().create_timer(4).timeout
				get_tree().change_scene_to_file("res://game/menu.tscn")

func is_valid_position(pos):
	if pos.x >= 0 and pos.y >= 0 and pos.x <= 4 and pos.y <= 6: return true
	return false

func is_mine(pos):
	if (white and board[pos.x][pos.y] == 1) or (!white and board[pos.x][pos.y] == -1): return true
	return false


func _on_a_pressed() -> void:
	coin(0)


func _on_b_pressed() -> void:
	coin(1)


func _on_c_pressed() -> void:
	coin(2)


func _on_d_pressed() -> void:
	coin(3)


func _on_e_pressed() -> void:
	coin(4)


func _on_f_pressed() -> void:
	coin(5)


func _on_g_pressed() -> void:
	coin(6)
