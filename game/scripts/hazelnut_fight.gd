extends Control

@onready var grid = [$"1_1", $"2_1", $"3_1", $"4_1", $"5_1", $"6_1", $"1_2", $"2_2", $"3_2", $"4_2", $"5_2", $"6_2", $"1_3", $"2_3", $"3_3", $"4_3", $"5_3", $"6_3", $"1_4", $"2_4", $"3_4", $"4_4", $"5_4", $"6_4", $"1_5", $"2_5", $"3_5", $"4_5", $"5_5", $"6_5", $"1_6", $"2_6", $"3_6", $"4_6", $"5_6", $"6_6"]
@onready var player: Panel = $player
@onready var next_player: Button = $next2

var turn = 0

var map = []
var map_loot = []

var pos = []

var rng = RandomNumberGenerator.new()

var player_turn = 1
var can_move = true
var can_look = true
var can_hide = false

var hazelnut_count = [0,0,0,0]

var p1_pos = []
var p1_count = []

var p2_pos = []
var p2_count = []

var p3_pos = []
var p3_count = []

var p4_pos = []
var p4_count = []

@onready var next: Button = $next2

@onready var players = [$player1, $player2, $player3, $player4]

#var HazelnutAi1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#HazelnutAi1 = preload("uid://c7cenmc5bdawx").new()
	
	if GameManager.Q1 == 0: pos = [Vector2(1,1),Vector2(6,6)]
	elif GameManager.Q1 == 1: pos = [Vector2(1,1),Vector2(6,6),Vector2(1,6)]
	else: pos = [Vector2(1,1),Vector2(6,6),Vector2(1,6),Vector2(6,1)]
	
	$turn.text = "turn: 0/" + str(GameManager.Q2*5)
	$win.visible = false
	
	next.visible = false

	hazelnuts_count()
	_position()

	if GameManager.Q1 < 4:
		$player4.visible = false
		if GameManager.Q1 < 3:
			$player3.visible = false

	player_turn = rng.randi_range(1,GameManager.Q1)
	$PlayerTurn.text = "Player " + str(player_turn) + " turn"
	if player_turn == 1:
		player.self_modulate = "cd733e"
		next_player.self_modulate = "cd733e"
	elif player_turn == 2:
		player.self_modulate = "adadad"
		next_player.self_modulate = "adadad"
	elif player_turn == 3:
		player.self_modulate = "ffffff"
		next_player.self_modulate = "ffffff"
	elif player_turn == 4:
		player.self_modulate = "ff7d31"
		next_player.self_modulate = "ff7d31"

	map.resize(grid.size())
	for i in grid.size():
		if rng.randi_range(1,2) == 1:
			grid[i].region_rect.position.x = 472
			map[i] = "plain"
		elif rng.randi_range(1,15) == 1:
			map[i] = "lake"
			grid[i].region_rect.position.x = 0
		else:
			map[i] = "forest"
			grid[i].region_rect.position.x = 944

	map_loot.resize(grid.size())
	for i in map_loot.size():
		if map[i] == "lake":
			map_loot[i] = 0
			
		elif map[i] == "plain":
			if rng.randi_range(1,3) == 1:
				map_loot[i] = 0
			elif rng.randi_range(1,2) == 1:
				map_loot[i] = 1
			elif rng.randi_range(1,2) == 1:
				map_loot[i] = 2
			else:
				map_loot[i] = 3
				
		else:
			if rng.randi_range(1,4) == 1:
				map_loot[i] = 0
			elif rng.randi_range(1,3) == 1:
				map_loot[i] = 1
			elif rng.randi_range(1,2) == 1:
				map_loot[i] = 2
			elif rng.randi_range(1,15) == 1:
				map_loot[i] = 6
			else:
				map_loot[i] = 3
	
	HazelnutAi.grid = map
	HazelnutAi.not_go_pos = []
	
	if GameManager.Bots > player_turn:
		player_turn -= 1
		turn -= 100
		_on_next_pressed()



func _on_next_pressed() -> void:
	
	if GameManager.Bots_difficulty == true:
		if HazelnutAi.not_go_pos.has(pos[player_turn-1]):
			var i = 0
			while not HazelnutAi.not_go_pos[i] == pos[player_turn-1]:
				i += 1
			HazelnutAi.not_go_pos.remove_at(i)
	

	if player_turn == GameManager.Q1:
		player_turn = 1
	else:
		player_turn += 1
	turn += 100
	
	var turns = round(int((turn / GameManager.Q1)*0.01))
	$turn.text = "turn: " + str(turns) + "/" + str(GameManager.Q2*5)
	if turns >= GameManager.Q2*5 + 1:
		_END()
	else:
		next.visible = true
	
	
	if GameManager.Bots > player_turn:
		
		
		pos[player_turn-1] = HazelnutAi.find_best_move(pos,player_turn)
		_position()
		_on_look_around_pressed()
		
		match hazelnut_count[player_turn-1]:
			1: _on_hide_1_pressed()
			2: _on_hide_2_pressed()
			3: _on_hide_3_pressed()
			4: _on_hide_4_pressed()
			5: _on_hide_5_pressed()
			6: _on_hide_6_pressed()
		
	else:
		next.visible = true


func _on_next_2_pressed() -> void:
	can_hide = false
	next.visible = false
	$PlayerTurn.text = "Player " + str(player_turn) + " turn"
	if player_turn == 1:
		player.self_modulate = "cd733e"
		next_player.self_modulate = "cd733e"
	elif player_turn == 2:
		player.self_modulate = "adadad"
		next_player.self_modulate = "adadad"
	elif player_turn == 3:
		player.self_modulate = "ffffff"
		next_player.self_modulate = "ffffff"
	elif player_turn == 4:
		player.self_modulate = "ff7d31"
		next_player.self_modulate = "ff7d31"
	hazelnuts_count()
	can_move = true
	can_look = true
	turn += 100
	var turns = round(int((turn / GameManager.Q1)*0.01))
	$turn.text = "turn: " + str(turns) + "/" + str(GameManager.Q2*5)
	if turns >= GameManager.Q2*5 + 1:
		_END()


func _on_look_around_pressed() -> void:
	if can_look == true:
		var gold = false
		if hazelnut_count[player_turn-1] == 6:
			gold = true
			hazelnut_count[player_turn-1] -= 6
		if map_loot[pos[player_turn-1].x -1 + (pos[player_turn-1].y -1) * 6] == 6:
			hazelnut_count[player_turn-1] = 6
			map_loot[pos[player_turn-1].x -1 + (pos[player_turn-1].y -1) * 6] = 0
			can_hide = true
			hazelnuts_count()
			can_look = false
		else:
			var count = 0
			if p1_pos.has(pos[player_turn-1]):
				for i in p1_pos.size():
					if p1_pos[i] == pos[player_turn-1]:
						count -= p1_count[i]
						p1_pos.erase(i)
						p1_count.erase(i)
			elif p2_pos.has(pos[player_turn-1]):
				for i in p2_pos.size():
					if p2_pos[i] == pos[player_turn-1]:
						count -= p2_count[i]
						p2_pos.erase(i)
						p2_count.erase(i)
			elif p3_pos.has(pos[player_turn-1]):
				for i in p3_pos.size():
					if p3_pos[i] == pos[player_turn-1]:
						count -= p3_count[i]
						p3_pos.erase(i)
						p3_count.erase(i)
			elif p4_pos.has(pos[player_turn-1]):
				for i in p4_pos.size():
					if p4_pos[i] == pos[player_turn-1]:
						count -= p4_count[i]
						p4_pos.erase(i)
						p4_count.erase(i)
			else:
				if (map_loot[pos[player_turn-1].x -1 + (pos[player_turn-1].y -1) * 6] + hazelnut_count[player_turn-1] ) > 5:
					for i in (map_loot[pos[player_turn-1].x -1 + (pos[player_turn-1].y -1) * 6] + hazelnut_count[player_turn-1] ) - 5:
						count += 1
			hazelnut_count[player_turn-1] += map_loot[pos[player_turn-1].x -1 + (pos[player_turn-1].y -1) * 6] - count
			map_loot[pos[player_turn-1].x -1 + (pos[player_turn-1].y -1) * 6] = count
			hazelnuts_count()
			can_look = false
			if gold == true:
				if player_turn == 1:
					p1_pos.insert(0,pos[player_turn-1])
					p1_count.insert(0,6)
				elif player_turn == 2:
					p2_pos.insert(0,pos[player_turn-1])
					p2_count.insert(0,6)
				elif player_turn == 3:
					p3_pos.insert(0,pos[player_turn-1])
					p3_count.insert(0,6)
				elif player_turn == 4:
					p4_pos.insert(0,pos[player_turn-1])
					p4_count.insert(0,6)
			else:
				can_hide = true
		_hide()

func hazelnuts_count():
	$"Hazelnut count/1".visible = false
	$"Hazelnut count/2".visible = false
	$"Hazelnut count/3".visible = false
	$"Hazelnut count/4".visible = false
	$"Hazelnut count/5".visible = false
	$"Hazelnut count/6".visible = false
	if hazelnut_count[player_turn-1] == 6:
		$"Hazelnut count/6".visible = true
	else:
		if hazelnut_count[player_turn-1] > 0:
			$"Hazelnut count/1".visible = true
		if hazelnut_count[player_turn-1] > 1:
			$"Hazelnut count/2".visible = true
		if hazelnut_count[player_turn-1] > 2:
			$"Hazelnut count/3".visible = true
		if hazelnut_count[player_turn-1] > 3:
			$"Hazelnut count/4".visible = true
		if hazelnut_count[player_turn-1] > 4:
			$"Hazelnut count/5".visible = true
	_hide()


func _position():
	players[0].position.x = (pos[0].x - 1) * 100 + 326.0
	players[0].position.y = (pos[0].y - 1) * 100 + 75.0
	
	players[1].position.x = (pos[1].x - 1) * 100 + 326.0
	players[1].position.y = (pos[1].y - 1) * 100 + 75.0
	
	if GameManager.Q1 > 1:
		players[2].position.x = (pos[2].x - 1) * 100 + 326.0
		players[2].position.y = (pos[2].y - 1) * 100 + 75.0
		if GameManager.Q1 > 2:
			players[3].position.x = (pos[3].x - 1) * 100 + 326.0
			players[3].position.y = (pos[3].y - 1) * 100 + 75.0
	
	can_hide = false

func _input(event: InputEvent) -> void:
	if can_move == true:
		if event.is_action("down"):
			if not pos[player_turn-1].y == 6:
				pos[player_turn-1].y += 1
				can_move = false
				_hide()
		elif event.is_action("up"):
			if not pos[player_turn-1].y == 1:
				pos[player_turn-1].y -= 1
				can_move = false
				_hide()
		elif event.is_action("left"):
			if not pos[player_turn-1].x == 1:
				pos[player_turn-1].x -= 1
				can_move = false
				_hide()
		elif event.is_action("right"):
			if not pos[player_turn-1].x == 6:
				pos[player_turn-1].x += 1
				can_move = false
				_hide()
		_position()


@onready var hide = [$"actions/Hide 1", $"actions/Hide 2", $"actions/Hide 3", $"actions/Hide 4", $"actions/Hide 5", $"actions/Hide 6"]

func _hide():
	for i in 6:
		hide[i].visible = false
	if hazelnut_count[player_turn-1] == 6:
		hide[5].visible = true
	else:
		if can_hide == true and not hazelnut_count[player_turn-1] == 6:
			for i in hazelnut_count[player_turn-1]:
				hide[i].visible = true


func _on_hide_1_pressed() -> void:
	if not p1_pos.has(pos[player_turn-1]) and not p2_pos.has(pos[player_turn-1]) and not p3_pos.has(pos[player_turn-1]) and not p4_pos.has(pos[player_turn-1]):
		if player_turn == 1:
			p1_pos.insert(0,pos[player_turn-1])
			p1_count.insert(0,1)
		elif player_turn == 2:
			p2_pos.insert(0,pos[player_turn-1])
			p2_count.insert(0,1)
		elif player_turn == 3:
			p3_pos.insert(0,pos[player_turn-1])
			p3_count.insert(0,1)
		elif player_turn == 4:
			p4_pos.insert(0,pos[player_turn-1])
			p4_count.insert(0,1)
		hazelnut_count[player_turn-1] -= 1
		hazelnuts_count()


func _on_hide_2_pressed() -> void:
	if player_turn == 1:
		p1_pos.insert(0,pos[player_turn-1])
		p1_count.insert(0,2)
	elif player_turn == 2:
		p2_pos.insert(0,pos[player_turn-1])
		p2_count.insert(0,2)
	elif player_turn == 3:
		p3_pos.insert(0,pos[player_turn-1])
		p3_count.insert(0,2)
	elif player_turn == 4:
		p4_pos.insert(0,pos[player_turn-1])
		p4_count.insert(0,2)
	hazelnut_count[player_turn-1] -= 2
	hazelnuts_count()


func _on_hide_3_pressed() -> void:
	if player_turn == 1:
		p1_pos.insert(0,pos[player_turn-1])
		p1_count.insert(0,3)
	elif player_turn == 2:
		p2_pos.insert(0,pos[player_turn-1])
		p2_count.insert(0,3)
	elif player_turn == 3:
		p3_pos.insert(0,pos[player_turn-1])
		p3_count.insert(0,3)
	elif player_turn == 4:
		p4_pos.insert(0,pos[player_turn-1])
		p4_count.insert(0,3)
	hazelnut_count[player_turn-1] -= 3
	hazelnuts_count()


func _on_hide_4_pressed() -> void:
	if player_turn == 1:
		p1_pos.insert(0,pos[player_turn-1])
		p1_count.insert(0,4)
	elif player_turn == 2:
		p2_pos.insert(0,pos[player_turn-1])
		p2_count.insert(0,4)
	elif player_turn == 3:
		p3_pos.insert(0,pos[player_turn-1])
		p3_count.insert(0,4)
	elif player_turn == 4:
		p4_pos.insert(0,pos[player_turn-1])
		p4_count.insert(0,4)
	hazelnut_count[player_turn-1] -= 4
	hazelnuts_count()


func _on_hide_5_pressed() -> void:
	if player_turn == 5:
		p1_pos.insert(0,pos[player_turn-1])
		p1_count.insert(0,5)
	elif player_turn == 2:
		p2_pos.insert(0,pos[player_turn-1])
		p2_count.insert(0,5)
	elif player_turn == 3:
		p3_pos.insert(0,pos[player_turn-1])
		p3_count.insert(0,5)
	elif player_turn == 4:
		p4_pos.insert(0,pos[player_turn-1])
		p4_count.insert(0,5)
	hazelnut_count[player_turn-1] -= 5
	hazelnuts_count()


func _on_hide_6_pressed() -> void:
	if player_turn == 1:
		p1_pos.insert(0,pos[player_turn-1])
		p1_count.insert(0,6)
	elif player_turn == 2:
		p2_pos.insert(0,pos[player_turn-1])
		p2_count.insert(0,6)
	elif player_turn == 3:
		p3_pos.insert(0,pos[player_turn-1])
		p3_count.insert(0,6)
	elif player_turn == 4:
		p4_pos.insert(0,pos[player_turn-1])
		p4_count.insert(0,6)
	hazelnut_count[player_turn-1] -= 6
	hazelnuts_count()

func _END():
	var p1 = 0
	var p2 = 0
	var p3 = 0
	var p4 = 0
	for i in p1_count.size():
		if p1_count[i] == 6:
			p1 += 10
		else:
			p1 += p1_count[i]
	for i in p2_count.size():
		if p2_count[i] == 6:
			p2 += 10
		else:
			p2 += p2_count[i]
	for i in p3_count.size():
		if p3_count[i] == 6:
			p3 += 10
		else:
			p3 += p3_count[i]
	for i in p4_count.size():
		if p4_count[i] == 6:
			p4 += 10
		else:
			p4 += p4_count[i]
	
	$"win/win2/1".visible = false
	$"win/win2/2".visible = false
	$"win/win2/3".visible = false
	$"win/win2/4".visible = false
	
	if p1 > p2 and p1 > p3 and p1 > p4:
		$win/win2/Label.text = "P1 Won!"
		$win/win2/Label2.text = "with " + str(p1) + " hazelnuts"
		$"win/win2/1".visible = true
		GameManager.PlayerVictory[0] += 1
	elif p2 > p1 and p2 > p3 and p2 > p4:
		$win/win2/Label.text = "P2 Won!"
		$win/win2/Label2.text = "with " + str(p2) + " hazelnuts"
		$"win/win2/2".visible = true
		GameManager.PlayerVictory[1] += 1
	elif p3 > p1 and p3 > p2 and p3 > p4:
		$win/win2/Label.text = "P3 Won!"
		$win/win2/Label2.text = "with " + str(p3) + " hazelnuts"
		$"win/win2/3".visible = true
		GameManager.PlayerVictory[2] += 1
	elif p4 > p1 and p4 > p2 and p4 > p3:
		$win/win2/Label.text = "P4 Won!"
		$win/win2/Label2.text = "with " + str(p4) + " hazelnuts"
		$"win/win2/4".visible = true
		GameManager.PlayerVictory[3] += 1
	$win.visible = true
	
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://game/menu.tscn")
