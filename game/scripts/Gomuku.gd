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
	
	board.resize(225)
	board.fill(0)
	
	
	board_buttons = [$"GridContainer/01", $"GridContainer/02", $"GridContainer/03", $"GridContainer/04", $"GridContainer/05", $"GridContainer/06", $"GridContainer/07", $"GridContainer/08", $"GridContainer/09", $"GridContainer/10", $"GridContainer/11", $"GridContainer/12", $"GridContainer/13", $"GridContainer/14", $"GridContainer/15", $"GridContainer/16", $"GridContainer/17", $"GridContainer/18", $"GridContainer/19", $"GridContainer/20", $"GridContainer/21", $"GridContainer/22", $"GridContainer/23", $"GridContainer/24", $"GridContainer/25", $"GridContainer/26", $"GridContainer/27", $"GridContainer/28", $"GridContainer/29", $"GridContainer/30", $"GridContainer/31", $"GridContainer/32", $"GridContainer/33", $"GridContainer/34", $"GridContainer/35", $"GridContainer/36", $"GridContainer/37", $"GridContainer/38", $"GridContainer/39", $"GridContainer/40", $"GridContainer/41", $"GridContainer/42", $"GridContainer/43", $"GridContainer/44", $"GridContainer/45", $"GridContainer/46", $"GridContainer/47", $"GridContainer/48", $"GridContainer/49", $"GridContainer/50", $"GridContainer/51", $"GridContainer/52", $"GridContainer/53", $"GridContainer/54", $"GridContainer/55", $"GridContainer/56", $"GridContainer/57", $"GridContainer/58", $"GridContainer/59", $"GridContainer/60", $"GridContainer/61", $"GridContainer/62", $"GridContainer/63", $"GridContainer/64", $"GridContainer/65", $"GridContainer/66", $"GridContainer/67", $"GridContainer/68", $"GridContainer/69", $"GridContainer/70", $"GridContainer/71", $"GridContainer/72", $"GridContainer/73", $"GridContainer/74", $"GridContainer/75", $"GridContainer/76", $"GridContainer/77", $"GridContainer/78", $"GridContainer/79", $"GridContainer/80", $"GridContainer/81", $"GridContainer/82", $"GridContainer/83", $"GridContainer/84", $"GridContainer/85", $"GridContainer/86", $"GridContainer/87", $"GridContainer/88", $"GridContainer/89", $"GridContainer/90", $"GridContainer/91", $"GridContainer/92", $"GridContainer/93", $"GridContainer/94", $"GridContainer/95", $"GridContainer/96", $"GridContainer/97", $"GridContainer/98", $"GridContainer/99", $"GridContainer/100", $"GridContainer/101", $"GridContainer/102", $"GridContainer/103", $"GridContainer/104", $"GridContainer/105", $"GridContainer/106", $"GridContainer/107", $"GridContainer/108", $"GridContainer/109", $"GridContainer/110", $"GridContainer/111", $"GridContainer/112", $"GridContainer/113", $"GridContainer/114", $"GridContainer/115", $"GridContainer/116", $"GridContainer/117", $"GridContainer/118", $"GridContainer/119", $"GridContainer/120", $"GridContainer/121", $"GridContainer/122", $"GridContainer/123", $"GridContainer/124", $"GridContainer/125", $"GridContainer/126", $"GridContainer/127", $"GridContainer/128", $"GridContainer/129", $"GridContainer/130", $"GridContainer/131", $"GridContainer/132", $"GridContainer/133", $"GridContainer/134", $"GridContainer/135", $"GridContainer/136", $"GridContainer/137", $"GridContainer/138", $"GridContainer/139", $"GridContainer/140", $"GridContainer/141", $"GridContainer/142", $"GridContainer/143", $"GridContainer/144", $"GridContainer/145", $"GridContainer/146", $"GridContainer/147", $"GridContainer/148", $"GridContainer/149", $"GridContainer/150", $"GridContainer/151", $"GridContainer/152", $"GridContainer/153", $"GridContainer/154", $"GridContainer/155", $"GridContainer/156", $"GridContainer/157", $"GridContainer/158", $"GridContainer/159", $"GridContainer/160", $"GridContainer/161", $"GridContainer/162", $"GridContainer/163", $"GridContainer/164", $"GridContainer/165", $"GridContainer/166", $"GridContainer/167", $"GridContainer/168", $"GridContainer/169", $"GridContainer/170", $"GridContainer/171", $"GridContainer/172", $"GridContainer/173", $"GridContainer/174", $"GridContainer/175", $"GridContainer/176", $"GridContainer/177", $"GridContainer/178", $"GridContainer/179", $"GridContainer/180", $"GridContainer/181", $"GridContainer/182", $"GridContainer/183", $"GridContainer/184", $"GridContainer/185", $"GridContainer/186", $"GridContainer/187", $"GridContainer/188", $"GridContainer/189", $"GridContainer/190", $"GridContainer/191", $"GridContainer/192", $"GridContainer/193", $"GridContainer/194", $"GridContainer/195", $"GridContainer/196", $"GridContainer/197", $"GridContainer/198", $"GridContainer/199", $"GridContainer/200", $"GridContainer/201", $"GridContainer/202", $"GridContainer/203", $"GridContainer/204", $"GridContainer/205", $"GridContainer/206", $"GridContainer/207", $"GridContainer/208", $"GridContainer/209", $"GridContainer/210", $"GridContainer/211", $"GridContainer/212", $"GridContainer/213", $"GridContainer/214", $"GridContainer/215", $"GridContainer/216", $"GridContainer/217", $"GridContainer/218", $"GridContainer/219", $"GridContainer/220", $"GridContainer/221", $"GridContainer/222", $"GridContainer/223", $"GridContainer/224", $"GridContainer/225"]
	
	var buttons = get_tree().get_nodes_in_group("buttons")
	
	for button in buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))

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
	for i in 225:
		if board[i] == 1:
			board_buttons[i].modulate = Color(1.0, 0.0, 0.0, 1.0)
		elif board[i] == 2:
			board_buttons[i].modulate = Color(0.0, 0.435, 1.0, 1.0)
		else:
			has = true
			board_buttons[i].modulate = Color(1.0, 1.0, 1.0, 1.0)
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
	
	if total > 4: end(false)
	
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
	
	if total > 4: end(false)
	
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
	if total > 4: end(false)
	
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
	if total > 4: end(false)
	
	red = !red

func is_valid_position(pos):
	if pos.x >= 0 and pos.y >= 0 and pos.x <= 14 and pos.y <= 14: return true
	return false

func is_mine(pos):
	if (red and board[pos.x+(pos.y*15)] == 1) or (!red and board[pos.x+(pos.y*15)] == 2): return true
	return false

func _on_button_pressed(button):
	var num_char = button.name
	
	if board[int(num_char)-1] == 0:
		if red:
			board[int(num_char)-1] = 1
		else:
			board[int(num_char)-1] = 2
		
		var pos
		
		pos = round((int(num_char)-1) / 15)
		
		$last.text += "x:" + str(pos+1) + " ,y:" + str(int(num_char)-(pos*15)) + "    "
		
		win_check(Vector2(int(num_char)-(pos*15)-1,pos))
		_display()
