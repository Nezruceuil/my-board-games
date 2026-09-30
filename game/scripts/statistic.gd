extends Control

var rng = RandomNumberGenerator.new()

var Player_turn = 0
var turn = 0

var cards = [0,0,0,0]

var Bank_account = [350,350,350,350]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$End.visible = false
	for i in 4:
		Bank_account[i] = GameManager.Q2 * 100 + 200
	_set_details()

func _set_details():
	$Game/P1.visible = true
	$Game.visible = false
	$card.visible = true
	$"next player2".visible = true
	Player_turn = rng.randi_range(1,GameManager.Q1)
	$"next player2".text = "Pass to player " + str(Player_turn)
	
	for i in GameManager.Q1 + 1:
		if not cards[i] == -1:
			if rng.randi_range(1,27) == 1:
				cards[i] = 15
			else:
				cards[i] = rng.randi_range(2,14)
	_show()

func _show():
	if cards[Player_turn-1] < 11:
		$card/number.text = str(cards[Player_turn-1])
	else:
		if cards[Player_turn-1] == 11:
			$card/number.text = "V"
		if cards[Player_turn-1] == 12:
			$card/number.text = "D"
		if cards[Player_turn-1] == 13:
			$card/number.text = "K"
		if cards[Player_turn-1] == 14:
			$card/number.text = "As"
		if cards[Player_turn-1] == 15:
			$card/number.text = "Jk"

func _on_next_player_2_pressed() -> void:
	$"next player2".visible = false

func _on_next_player_pressed() -> void:
	if Player_turn >= GameManager.Q1 + 1:
		Player_turn = 0
	turn += 1
	Player_turn += 1
	if not cards[Player_turn-1] == -1:
		$"next player2".visible = true
		if turn == GameManager.Q1 + 1:
			$"next player2".text = "Start the Game!"
			$card.visible = false
			$Game.visible = true
			$Game/Stop.visible = false
			$Game/next_player_turn.visible = false
			_reload()
		else:
			$"next player2".text = "Pass to player " + str(Player_turn)
		_show()
	else:
		_on_next_player_pressed()

 

##GAME!

var money_spend = [0,0,0,0]
var current_bet = 0
var total_bet = 0

func _on_5_pressed() -> void:
	if not money_spend[Player_turn] + 5 > Bank_account[Player_turn-1]:
		if 5 >= current_bet:
			money_spend[Player_turn-1] += 5
			current_bet = 5
			total_bet += 5
			_reload()
			can_pass()


func _on_15_pressed() -> void:
	if not money_spend[Player_turn] + 15 > Bank_account[Player_turn-1]:
		if 15 >= current_bet:
			money_spend[Player_turn-1] += 15
			current_bet = 15
			total_bet += 15
			_reload()
			can_pass()


func _on_30_pressed() -> void:
	if not money_spend[Player_turn-1] + 30 > Bank_account[Player_turn-1]:
		if 30 >= current_bet:
			money_spend[Player_turn-1] += 30
			current_bet = 30
			total_bet += 30
			_reload()
			can_pass()


func _on_50_pressed() -> void:
	if not money_spend[Player_turn-1] + 50 > Bank_account[Player_turn-1]:
		if 50 >= current_bet:
			money_spend[Player_turn-1] += 50
			current_bet = 50
			total_bet += 50
			_reload()
			can_pass()


func _on_70_pressed() -> void:
	if not money_spend[Player_turn-1] + 70 > Bank_account[Player_turn-1]:
		if 70 >= current_bet:
			money_spend[Player_turn-1] += 70
			current_bet = 70
			total_bet += 70
			_reload()
			can_pass()


func _on_85_pressed() -> void:
	if not money_spend[Player_turn-1] + 85 > Bank_account[Player_turn-1]:
		if 85 >= current_bet:
			money_spend[Player_turn-1] += 85
			current_bet = 85
			total_bet += 85
			_reload()
			can_pass()


func _on_100_pressed() -> void:
	if not money_spend[Player_turn-1] + 100 > Bank_account[Player_turn-1]:
		if 100 >= current_bet:
			money_spend[Player_turn-1] += 100
			current_bet = 100
			total_bet += 100
			_reload()
			can_pass()

func _reload():
	$Game/Bet.text = "Current Bet: " + str(current_bet)
	$Game/Spend.text = "Money Spend:" + str(money_spend[Player_turn-1]) + "/" + str(Bank_account[Player_turn-1])
	$Game/turn.text = "Player " + str(Player_turn) + " turn"

func can_pass():
	$Game/next_player_turn.visible = true
	$Game/Stop.visible = true
	$Game/P1.visible = false


func _on_next_player_turn_pressed() -> void:
	_next_player(0)

func _next_player(num):
	if num == GameManager.Q1:
		if Player_turn == GameManager.Q1 + 1:
			Player_turn = 0
		Player_turn += 1
		_end()
	else:
		
		$Game/next_player_turn.visible = false
		$Game/Stop.visible = false
		if Player_turn == GameManager.Q1 + 1:
			Player_turn = 0
		Player_turn += 1
		_reload()
		$Game/P1.visible = true
		
		if current_bet > Bank_account[Player_turn-1] - money_spend[Player_turn-1]:
			cards[Player_turn-1] = -1
			_next_player(num + 1)


func _on_stop_pressed() -> void:
	var number = 0
	Bank_account[0] -= money_spend[0]
	Bank_account[1] -= money_spend[1]
	Bank_account[2] -= money_spend[2]
	Bank_account[3] -= money_spend[3]
	for i in (GameManager.Q1 + 1):
		if cards[i] >= cards[0] and cards[i] >= cards[1] and cards[i] >= cards[2] and cards[i] >= cards[3]:
			number += 1
	for i in (GameManager.Q1 + 1):
		if cards[i] >= cards[1] and cards[i] >= cards[2] and cards[i] >= cards[3]  and cards[i] >= cards[0]:
			Bank_account[i] += (total_bet / number)

	_reload()
	for i in 4:
		if not cards[i] == -1:
			cards[i] = 0
	turn = 0
	Player_turn = 0
	money_spend = [0,0,0,0]
	current_bet = 0
	total_bet = 0
	_set_details()

func _end():
	$End/Panel/Label.text = 'P' + str(Player_turn) + ' WIN !'
	match Player_turn:
		1: $End/Panel/Winner.modulate = Color(1.0, 0.0, 0.0, 1.0)
		2: $End/Panel/Winner.modulate = Color(0.0, 0.0, 1.0, 1.0)
		3: $End/Panel/Winner.modulate = Color(0.0, 1.0, 0.0, 1.0)
		4: $End/Panel/Winner.modulate = Color(1.0, 1.0, 0.0, 1.0)
	
	$End.visible = true
	
	GameManager.PlayerVictory[Player_turn-1] += 1
	
	await get_tree().create_timer(4).timeout
	get_tree().change_scene_to_file("res://game/menu.tscn")
