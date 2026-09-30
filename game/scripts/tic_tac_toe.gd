extends Control

var board : Array
var board_buttons : Array

var red = true
var first = true

var timer = null

func _process(delta: float) -> void:
	if not timer == null:
		if red:
			timer.x -= delta
			$Timer.text = "TIME LEFT: " + str(round(timer.x*100)/100) + " s"
			if timer.x < 0:
				red = !red
				end(false)
		else:
			timer.y -= delta
			$Timer.text = "TIME LEFT: " + str(round(timer.y*100)/100) + "  s"
			if timer.y < 0:
				red = !red
				end(false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.Q2 == 2:
		$Timer.visible = false
	elif GameManager.Q2 == 1:
		timer = Vector2(60,60)
	else:
		timer = Vector2(900,900)
	
	board.append([0,0,0,0,0])
	board.append([0,0,0,0,0])
	board.append([0,0,0,0,0])
	board.append([0,0,0,0,0])
	board.append([0,0,0,0,0])
	
	
	board_buttons.append([$"GridContainer/1_1", $"GridContainer/2_1", $"GridContainer/3_1", $"GridContainer/4_1", $"GridContainer/5_1"])
	board_buttons.append([$"GridContainer/1_2", $"GridContainer/2_2", $"GridContainer/3_2", $"GridContainer/4_2", $"GridContainer/5_2"])
	board_buttons.append([$"GridContainer/1_3", $"GridContainer/2_3", $"GridContainer/3_3", $"GridContainer/4_3", $"GridContainer/5_3"])
	board_buttons.append([$"GridContainer/1_4", $"GridContainer/2_4", $"GridContainer/3_4", $"GridContainer/4_4", $"GridContainer/5_4"])
	board_buttons.append([$"GridContainer/1_5", $"GridContainer/2_5", $"GridContainer/3_5", $"GridContainer/4_5", $"GridContainer/5_5"])

func end(draw):
	$Win.visible = true
	if draw:
		GameManager.PlayerVictory[0] += 0.5
		GameManager.PlayerVictory[1] += 0.5
		$Win/Label.text = "Draw"
		await get_tree().create_timer(4).timeout
		get_tree().change_scene_to_file("res://game/menu.tscn")
	elif !red:
		GameManager.PlayerVictory[1] += 1
		$Win/Label.text = "Blue win"
		await get_tree().create_timer(4).timeout
		get_tree().change_scene_to_file("res://game/menu.tscn")
	else:
		GameManager.PlayerVictory[0] += 1
		$Win/Label.text = "Red win"
		await get_tree().create_timer(4).timeout
		get_tree().change_scene_to_file("res://game/menu.tscn")

func _display():
	if red: $Label.text = "P1 Turn"
	else: $Label.text = "P2 Turn"
	
	var has = false
	for i in 5:
		for j in 5:
			if board[i][j] == 1:
				board_buttons[i][j].modulate = Color(1.0, 0.0, 0.0, 1.0)
			elif board[i][j] == 2:
				board_buttons[i][j].modulate = Color(0.0, 0.435, 1.0, 1.0)
			else:
				has = true
				board_buttons[i][j].modulate = Color(1.0, 1.0, 1.0, 1.0)
	if has == false:
		end(true)
	first = false

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
	
	# \/ /\
	total = 0
	direction = Vector2(1,0)
	position = pos
	while is_valid_position(position) and is_mine(position):
		total += 1
		position += direction
	
	position = pos - direction
	while is_valid_position(position) and is_mine(position):
		total += 1
		position -= direction
	
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
	
	red = !red

func is_valid_position(pos):
	if pos.x >= 0 and pos.y >= 0 and pos.x <= 4 and pos.y <= 4: return true
	return false

func is_mine(pos):
	if (red and board[pos.x][pos.y] == 1) or (!red and board[pos.x][pos.y] == 2): return true
	return false

func _on_1_1_pressed() -> void:
	if board[0][0] == 0:
		if red:
			board[0][0] = 1
		else:
			board[0][0] = 2
		win_check(Vector2(0,0))
		_display()


func _on_2_1_pressed() -> void:
	if board[0][1] == 0:
		if red:
			board[0][1] = 1
		else:
			board[0][1] = 2
		win_check(Vector2(0,1))
		_display()


func _on_3_1_pressed() -> void:
	if board[0][2] == 0:
		if red:
			board[0][2] = 1
		else:
			board[0][2] = 2
		win_check(Vector2(0,2))
		_display()


func _on_4_1_pressed() -> void:
	if board[0][3] == 0:
		if red:
			board[0][3] = 1
		else:
			board[0][3] = 2
		win_check(Vector2(0,3))
		_display()


func _on_5_1_pressed() -> void:
	if board[0][4] == 0:
		if red:
			board[0][4] = 1
		else:
			board[0][4] = 2
		win_check(Vector2(0,4))
		_display()


func _on_1_2_pressed() -> void:
	if board[1][0] == 0:
		if red:
			board[1][0] = 1
		else:
			board[1][0] = 2
		win_check(Vector2(1,0))
		_display()


func _on_2_2_pressed() -> void:
	if board[1][1] == 0:
		if red:
			board[1][1] = 1
		else:
			board[1][1] = 2
		win_check(Vector2(1,1))
		_display()


func _on_3_2_pressed() -> void:
	if board[1][2] == 0:
		if red:
			board[1][2] = 1
		else:
			board[1][2] = 2
		win_check(Vector2(1,2))
		_display()


func _on_4_2_pressed() -> void:
	if board[1][3] == 0:
		if red:
			board[1][3] = 1
		else:
			board[1][3] = 2
		win_check(Vector2(1,3))
		_display()


func _on_5_2_pressed() -> void:
	if board[1][4] == 0:
		if red:
			board[1][4] = 1
		else:
			board[1][4] = 2
		win_check(Vector2(1,4))
		_display()


func _on_1_3_pressed() -> void:
	if board[2][0] == 0:
		if red:
			board[2][0] = 1
		else:
			board[2][0] = 2
		win_check(Vector2(2,0))
		_display()


func _on_2_3_pressed() -> void:
	if board[2][1] == 0:
		if red:
			board[2][1] = 1
		else:
			board[2][1] = 2
		win_check(Vector2(2,1))
		_display()


func _on_3_3_pressed() -> void:
	if first == false:
		if board[2][2] == 0:
			if red:
				board[2][2] = 1
			else:
				board[2][2] = 2
			win_check(Vector2(2,2))
			_display()


func _on_4_3_pressed() -> void:
	if board[2][3] == 0:
		if red:
			board[2][3] = 1
		else:
			board[2][3] = 2
		win_check(Vector2(2,3))
		_display()


func _on_5_3_pressed() -> void:
	if board[2][4] == 0:
		if red:
			board[2][4] = 1
		else:
			board[2][4] = 2
		win_check(Vector2(2,4))
		_display()


func _on_1_4_pressed() -> void:
	if board[3][0] == 0:
		if red:
			board[3][0] = 1
		else:
			board[3][0] = 2
		win_check(Vector2(3,0))
		_display()


func _on_2_4_pressed() -> void:
	if board[3][1] == 0:
		if red:
			board[3][1] = 1
		else:
			board[3][1] = 2
		win_check(Vector2(3,1))
		_display()


func _on_3_4_pressed() -> void:
	if board[3][2] == 0:
		if red:
			board[3][2] = 1
		else:
			board[3][2] = 2
		win_check(Vector2(3,2))
		_display()


func _on_4_4_pressed() -> void:
	if board[3][3] == 0:
		if red:
			board[3][3] = 1
		else:
			board[3][3] = 2
		win_check(Vector2(3,3))
		_display()


func _on_5_4_pressed() -> void:
	if board[3][4] == 0:
		if red:
			board[3][4] = 1
		else:
			board[3][4] = 2
		win_check(Vector2(3,4))
		_display()


func _on_1_5_pressed() -> void:
	if board[4][0] == 0:
		if red:
			board[4][0] = 1
		else:
			board[4][0] = 2
		win_check(Vector2(4,0))
		_display()


func _on_2_5_pressed() -> void:
	if board[4][1] == 0:
		if red:
			board[4][1] = 1
		else:
			board[4][1] = 2
		win_check(Vector2(4,1))
		_display()


func _on_3_5_pressed() -> void:
	if board[4][2] == 0:
		if red:
			board[4][2] = 1
		else:
			board[4][2] = 2
		win_check(Vector2(4,2))
		_display()


func _on_4_5_pressed() -> void:
	if board[4][3] == 0:
		if red:
			board[4][3] = 1
		else:
			board[4][3] = 2
		win_check(Vector2(4,3))
		_display()


func _on_5_5_pressed() -> void:
	if board[4][4] == 0:
		if red:
			board[4][4] = 1
		else:
			board[4][4] = 2
		win_check(Vector2(4,4))
		_display()
