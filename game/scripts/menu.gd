extends Node2D

var game_name = ""
var credits = ""
var text = false
var questions_1 : Dictionary = {
		"name" = "Q1",
		"Q1" = "1",
		"Q2" = "2",
		"Q3" = "3"}
var questions_2 : Dictionary = {
		"name" = "Q2",
		"Q1" = "1",
		"Q2" = "2",
		"Q3" = "3"}
var estimated_time = 0
var recommanded = false

var number = 0

var detail_num = 0
var details = [
				'Hazelnut Fight is a game where you move your squirrel on any adjacent square that are not diagonally. You can search for hazelnuts and hide hazelnuts on any square. To win you need to have the most points (hazelnuts = 1, gold hazelnuts = 10) at the end of the round.',
				'Pizza Chess is a chess variant in which the left knight is replaced by a "pizza," a piece capable of moving like a knight or traveling two squares horizontally or vertically.',
				"Every player has a hiden card the person with the most high value card will win the gamble money. Player take turn adding gambling money at any time someone can stop the game and do a reset of the card. When a player can't gamble anymore they are eliminated the last person standing wins",
				"Chess is a classic game with complex rules; if you wish to learn them, visit this site: 'https://en.wikipedia.org/wiki/Rules_of_chess'",
				'Drawback chess is a chess variant in which you have a secret rule—unknown to the other player—that puts you at a disadvantage.',
				'Pieces Fit is a game where you need to fit the most custom chess pieces without any of them attacking another.',
				'',
				'Connect 4 is a game where you make one of your coins fall in a hole when it is your turn, you need to have 4 coins in a row horizontally, vertically, or diagonally to win.',
				"Shōgi is a classic game with complex rules; if you wish to learn them, visit this site: 'https://en.wikipedia.org/wiki/Shogi'",
				'Each turn has two parts: First, move one of your amazons any number of squares horizontally, vertically, or diagonally. Second, that amazon shoots an arrow that travels in a straight line and burns the square it lands on. This square is now permanently blocked.',
				"Castle War is a Strategy game that I invented it is played on a 9*9 board. Player take turn moving a piece. If your king gets taken you lose the game every pieces has their own movement. More information: ''",
				'Better tic tac toe is a game played on a 5 by 5 grid where you place a coin of your color every turn. You win by having 4 of your coins horizontally vertically or diagonally aligned. The first player is not allowed to play in the middle on the first turn.',
				"Players take turns placing one disk on an empty square. After a play is made, any disks of the opponent's that lie in a straight line bounded by the one just played and another one change owner. When there are not empty squares left, the player with more disks wins the game.",
				"Tafl games are a family of ancient Northern European strategy board games played on a checkered or latticed gameboard with two armies of uneven numbers: more information:                         'https://en.wikipedia.org/wiki/Tafl_games'",
				'Go is a game where you need to have the most stones of your color at the end of the game, players takes turn placing a stone of their color of any intersection. Stone can capture by encircling other(s) stone(s)! The game end when no player plays consecutively.',
				"The object of the game is to bring all of your pieces together into a contiguous body so that all pieces are connected orthogonally or diagonally, Pieces move like a queen in  chess but they can jump over their own pieces.",
				"Gomoku is a classic board game you take turn placing a stone, to win you need to have 5 of your coins horizontally vertically or diagonally aligned."
				]

@onready var Questions = [$"Control/play?/Panel2/Q1/Button", $"Control/play?/Panel2/Q1/Button2", $"Control/play?/Panel2/Q1/Button3", $"Control/play?/Panel2/Q2/Button", $"Control/play?/Panel2/Q2/Button2", $"Control/play?/Panel2/Q2/Button3"]

var variants = ["Atomic","Duck Chess","Fog Of War","Give away","King Of The Hill","Capture Anything","Torpedo","No Castling","Ghost Board","Sideways","Horde","Racing Kings","Inverted Pawns","Random!","Monster Chess","Pawn Game","Chaturaji","4 Player Chess"]
var variants_time = [40,60,60,30,50,50,55,55,60,60,50,30,50,60,55,30,70,80]
var variant_details = [
				'Atomic is a chess variant that deletes all surrounding pieces (left, right, up, down) when there is a capture.',
				"Duck Chess is a chess variant where, after your move, you also move the duck on any empty square; it blocks that square like a wall for both players until moved again.",
				'Fog of War is a chess variant where you are unable to see the other half of the board.',
				'Give away is a chess variant where every capture is forced and you need to not have any pieces left to win.',
				'King of the Hill is a chess variant where you can also win by moving your king to the middle of the board.',
				'Capture anything is a chess variant where you can eat your own pieces.',
				'Torpedo is a chess variant that makes your pawns always able to move 2 tiles forward.',
				'No Castling is a Chess variant where Castling is not allowed.',
				"Ghost Board is a Chess variant where the board is invisible and you can't see your moving options.",
				'Sideways is a Chess variant where your pawn can also move sideways (left or right).',
				'Horde is a Chess variant where the white pieces are replaced with a horde of pawns.',
				"Racing Kings is a Chess variant where you can also win by getting to the last rank.",
				"Inverted Pawns is a Chess variant where pawn move like they eat and eat like they move.",
				"Random! makes it so you get a random unknown variant every time it is black turn. Include: Atomic, Fog of War, Capture anything, Torpedo, No Castling, Sideways and Inverted Pawns",
				"Monster chess make it so one person get only their pawns and rooks but can move twice every turns.",
				"Pawn Game is a variant of chess that makes it so every non pawn pieces are replaced by pawns (You can still promote your pawns!)",
				
				'Chaturaji is a 4 player version of chess where pawns promote to rooks, you win by having the most points when only one player is left, you gain points by eating other alive players\' material: king/boat=5, rook/bishop/knight=3, pawn=1.',
				'4 Player chess is a 4 player version of chess on a 12*12 size board. You win by been the last player alive. When a player die(lose his king) his team disappear. Castling is not allowed and pawn always promote to a queen.'
				]


const Panel_texture = [
						preload("uid://htob14neeao4"), # Winter
						preload("uid://blhjnwuvn55te"), # Spring
						preload("uid://c6t3rwoco7amg"), # Summer
						preload("uid://bmjgwf73q8wvf"), # Autumn
						preload("uid://blup6w24yncml"), # Openvoxel
						preload("uid://b6nyxbwxq0h5r"), # Stardance
						preload("uid://dw3hlucqtqqmq"), # Chess
						preload("uid://dlibrmgiqsw40") # Duck
						]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Engine.time_scale = 1
	
	var day = Time.get_datetime_dict_from_system(true)["day"]
	var month = Time.get_datetime_dict_from_system(true)["month"]
	
	if month == 6 or month == 7 or month == 8:
		# Summer
		if SaveManager.content_to_save["has_theme"][2] == false:
			$Control/Panel.texture = Panel_texture[2]
			SaveManager.content_to_save["has_theme"][2] = true
		else: $Control/Panel.texture = Panel_texture[SaveManager.content_to_save["current_theme"]]
	elif month == 9 or month == 10 or month == 11:
		# Autumn
		if SaveManager.content_to_save["has_theme"][3] == false:
			$Control/Panel.texture = Panel_texture[3]
			SaveManager.content_to_save["has_theme"][3] = true
		else: $Control/Panel.texture = Panel_texture[SaveManager.content_to_save["current_theme"]]
	elif (month == 12 or month == 1) or (month == 2 and day < 28):
		# Winter
		if SaveManager.content_to_save["has_theme"][0] == false:
			$Control/Panel.texture = Panel_texture[0]
			SaveManager.content_to_save["has_theme"][0] = true
		else: $Control/Panel.texture = Panel_texture[SaveManager.content_to_save["current_theme"]]
	else:
		# Spring
		if SaveManager.content_to_save["has_theme"][1] == false:
			$Control/Panel.texture = Panel_texture[1]
			SaveManager.content_to_save["has_theme"][1] = true
		else: $Control/Panel.texture = Panel_texture[SaveManager.content_to_save["current_theme"]]
	
	SaveManager._save()
	
	if SaveManager.content_to_save["box color"] is Color:
		$Control/options/Panel2/boxes.color = Color(SaveManager.content_to_save["box color"])
	
	_on_quit_pressed()
	Qs()
	$"Control/victory's".text = "Victory's : P1=" + str(GameManager.PlayerVictory[0]) + " ; P2=" + str(GameManager.PlayerVictory[1]) + " ; P3=" + str(GameManager.PlayerVictory[2]) + " ; P4=" + str(GameManager.PlayerVictory[3])

	for i in variants.size():
		$"Control/play?/Possibility/Panel/Games".text += variants[i]
		if not i == variants.size()-1:
			if (i +1) %2 == 0:
				$"Control/play?/Possibility/Panel/Games".text += "
				"
			else:
				$"Control/play?/Possibility/Panel/Games".text += "               "
	$Control/UI/Games/GridContainer.position.y = 10
	
	$Control/options/Themes.visible = false
	
	GameManager.color = $Control/options/Panel2/boxes.color
	
	order()


func _on_v_slider_value_changed(value: float) -> void:
	$Control/UI/Games/GridContainer.position.y = value * 43.2 - 4310.0

func _on_game_1_pressed() -> void:
	detail_num = 0
	text = false
	game_name = "Hazelnut fight"
	credits = "Made and designed by Nezruceuil"
	questions_1["name"] = "Players:"
	questions_1["Q1"] = "2 players"
	questions_1["Q2"] = "3 players"
	questions_1["Q3"] = "4 players"
	questions_2["name"] = "Turns:"
	questions_2["Q1"] = "short (5 turns)"
	questions_2["Q2"] = "normal (10 turns)"
	questions_2["Q3"] = "looong (15 turns)"
	estimated_time = 15
	recommanded = false
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 15


func _on_game_2_pressed() -> void:
	detail_num = 1
	text = false
	game_name = "Pizza chess"
	credits = "Modified by Nezruceuil"
	questions_1["name"] = "Additional rules:"
	questions_1["Q1"] = "PIZZA LOVER"
	questions_1["Q2"] = "NONE"
	questions_1["Q3"] = "SNEAKY BUSHES"
	questions_2["name"] = "Mode:"
	questions_2["Q1"] = "MEGA PIZZA!"
	questions_2["Q2"] = "Classic"
	questions_2["Q3"] = "823 551"
	estimated_time = 75
	recommanded = false
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 9


func _on_game_3_pressed() -> void:
	detail_num = 2
	text = false
	game_name = "Gamble"
	credits = "Who doesn't like gambling ?"
	questions_1["name"] = "Players"
	questions_1["Q1"] = "2 players"
	questions_1["Q2"] = "3 players"
	questions_1["Q3"] = "4 players"
	questions_2["name"] = "Starting Money:"
	questions_2["Q1"] = "300"
	questions_2["Q2"] = "400"
	questions_2["Q3"] = "500"
	estimated_time = 40
	recommanded = false
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 14


func _on_game_4_pressed() -> void:
	detail_num = 3
	text = false
	game_name = "Chess"
	credits = "Classic board game"
	questions_1["name"] = "Mode"
	questions_1["Q1"] = "2 408"
	questions_1["Q2"] = "classic"
	questions_1["Q3"] = "Blindfold"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "1 min"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "5 min"
	estimated_time = 70
	recommanded = false
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 0


func _on_game_5_pressed() -> void:
	detail_num = 4
	text = false
	game_name = "Drawback Chess"
	credits = "a Version of Chess"
	questions_1["name"] = "Mode"
	questions_1["Q1"] = "2 408"
	questions_1["Q2"] = "classic"
	questions_1["Q3"] = "Blindfold"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "5 min"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "10 min"
	estimated_time = 80
	recommanded = true
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 1


func _on_game_6_pressed() -> void:
	detail_num = 5
	text = false
	game_name = "Pieces fit"
	credits = "a unique Version of Chess"
	questions_1["name"] = "Difficulty"
	questions_1["Q1"] = "Classic"
	questions_1["Q2"] = "Normal"
	questions_1["Q3"] = "HARD!"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "1 min"
	questions_2["Q2"] = "5 min"
	questions_2["Q3"] = "10 min"
	estimated_time = 15
	recommanded = false
	play()
	GameManager.Q1 = 1
	GameManager.Q2 = 2
	Qs()
	number = 13


func _on_game_7_pressed() -> void:
	detail_num = 6
	text = true
	$"Control/play?/Panel2/text".text = ""
	game_name = "Chess variants"
	credits = "lots of unique Variants of Chess"
	questions_1["name"] = "Variant:"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "1 min"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "5 min"
	estimated_time = 40
	recommanded = true
	play()
	GameManager.Q1 = 0
	GameManager.Q2 = 2
	Qs()
	number = 3


func _on_game_8_pressed() -> void:
	detail_num = 7
	text = false
	game_name = "Connect 4"
	credits = "Classic board game"
	questions_1["name"] = "Mode"
	questions_1["Q1"] = "Most lines"
	questions_1["Q2"] = "classic"
	questions_1["Q3"] = "Blindfold"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "30 sec"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "1 min"
	estimated_time = 20
	recommanded = false
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 7


func _on_game_9_pressed() -> void:
	detail_num = 8
	text = false
	game_name = "Shōgi"
	credits = "Classic board game"
	questions_1["name"] = "Mode"
	questions_1["Q1"] = "2 408"
	questions_1["Q2"] = "classic"
	questions_1["Q3"] = "Blindfold"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "5 min"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "15 min"
	estimated_time = 90
	recommanded = false
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 2


func _on_game_10_pressed() -> void:
	detail_num = 9
	text = false
	game_name = "Amazons"
	credits = "Classic strategie game"
	questions_1["name"] = "Mode"
	questions_1["Q1"] = "Rook movement"
	questions_1["Q2"] = "classic"
	questions_1["Q3"] = "Blindfold"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "1 min"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "5 min"
	estimated_time = 75
	recommanded = false
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 10


func _on_game_11_pressed() -> void:
	detail_num = 10
	text = false
	game_name = "Castle War"
	credits = "Made and designed by Nezruceuil"
	questions_1["name"] = "Mode"
	questions_1["Q1"] = "Small"
	questions_1["Q2"] = "Classic"
	questions_1["Q3"] = "GIANT!"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "10 min"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "15 min"
	estimated_time = 99
	recommanded = true
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 4


func _on_game_12_pressed() -> void:
	detail_num = 11
	text = false
	game_name = "Better tic tac toe"
	credits = "Classic board game"
	questions_1["name"] = "Mode"
	questions_1["Q1"] = "Gomoku"
	questions_1["Q2"] = "Better tic tac toe"
	questions_1["Q3"] = "Blindfold Gomoku"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "1 min"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "15 min"
	estimated_time = 5
	recommanded = false
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 11


func _on_game_13_pressed() -> void:
	detail_num = 12
	text = false
	game_name = "Reversi"
	credits = "Classic board game"
	questions_1["name"] = "Mode"
	questions_1["Q1"] = "taken corner"
	questions_1["Q2"] = "classic"
	questions_1["Q3"] = "Blindfold"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "1 min"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "5 min"
	estimated_time = 25
	recommanded = true
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 8


func _on_game_14_pressed() -> void:
	detail_num = 13
	text = false
	game_name = "Tafl games"
	credits = "Classic viking board game"
	questions_1["name"] = "Mode"
	questions_1["Q1"] = "Ard-Ri"
	questions_1["Q2"] = "Fidchell"
	questions_1["Q3"] = "Brandubh"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "1 min"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "5 min"
	estimated_time = 25
	recommanded = true
	play()
	var rng = RandomNumberGenerator.new()
	GameManager.Q1 = rng.randi_range(1,3)
	GameManager.Q2 = 2
	Qs()
	number = 5


func _on_game_15_pressed() -> void:
	detail_num = 14
	text = false
	game_name = "GO"
	credits = "Classic board game"
	questions_1["name"] = "Mode"
	questions_1["Q1"] = "starting grid"
	questions_1["Q2"] = "classic"
	questions_1["Q3"] = "Blindfold"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "1 min"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "5 min"
	estimated_time = 120
	recommanded = false
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 6


func _on_game_16_pressed() -> void:
	detail_num = 15
	text = false
	game_name = "Lines of action"
	credits = "Classic board game"
	questions_1["name"] = "Mode"
	questions_1["Q1"] = "72"
	questions_1["Q2"] = "classic"
	questions_1["Q3"] = "Blindfold"
	questions_2["name"] = "Time"
	questions_2["Q1"] = "1 min"
	questions_2["Q2"] = "/"
	questions_2["Q3"] = "5 min"
	estimated_time = 20
	recommanded = false
	play()
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	Qs()
	number = 12


func play():
	GameManager.Q1 = 2
	GameManager.Q2 = 2
	
	$"Control/play?/Possibility".visible = false
	if text == false:
		$"Control/play?/Panel2/Q1".visible = true
		$"Control/play?/Panel2/text".visible = false
		$"Control/play?/Panel2/Games".visible = false
	else:
		$"Control/play?/Panel2/Q1".visible = false
		$"Control/play?/Panel2/text".visible = true
		$"Control/play?/Panel2/Games".visible = true
	
	$"Control/play?/Panel2/title".text = game_name
	$"Control/play?/Panel2/Credits".text = credits
	
	$"Control/play?/Panel2/Qlabel1".text = questions_1["name"]
	$"Control/play?/Panel2/Qlabel2".text = questions_2["name"]
	
	$"Control/play?/Panel2/Q1/Button".text = questions_1["Q1"]
	$"Control/play?/Panel2/Q1/Button2".text = questions_1["Q2"]
	$"Control/play?/Panel2/Q1/Button3".text = questions_1["Q3"]
	
	$"Control/play?/Panel2/Q2/Button".text = questions_2["Q1"]
	$"Control/play?/Panel2/Q2/Button2".text = questions_2["Q2"]
	$"Control/play?/Panel2/Q2/Button3".text = questions_2["Q3"]
	
	if recommanded == true:
		$"Control/play?/Panel2/star".modulate = "ffffff"
	else:
		$"Control/play?/Panel2/star".modulate = "1b1b1b"
	
	if estimated_time >= 60:
		$"Control/play?/Panel2/Time".text = "≈" + str(((estimated_time*100)/60)*0.01) + "h"
	else:
		$"Control/play?/Panel2/Time".text = "≈" + str(estimated_time) + "min"
	
	$"Control/play?".visible = true
	Qs()


func _on_Q1_1_pressed() -> void:
	GameManager.Q1 = 1
	Qs()


func _on_Q1_2_pressed() -> void:
	GameManager.Q1 = 2
	Qs()


func _on_Q1_3_pressed() -> void:
	GameManager.Q1 = 3
	Qs()


func _on_Q2_1_pressed() -> void:
	GameManager.Q2 = 1
	Qs()


func _on_Q2_2_pressed() -> void:
	GameManager.Q2 = 2
	Qs()


func _on_Q2_3_pressed() -> void:
	GameManager.Q2 = 3
	Qs()


func Qs():
	if game_name == "Better tic tac toe" or game_name == "Gomoku":
		if GameManager.Q1 == 2:
			detail_num = 11
			game_name = "Better tic tac toe"
			estimated_time = 5
		else:
			detail_num = 16
			game_name = "Gomoku"
			estimated_time = 40
		$"Control/play?/Panel2/title".text = game_name
		if estimated_time >= 60:
			$"Control/play?/Panel2/Time".text = "≈" + str(((estimated_time*100)/60)*0.01) + "h"
		else:
			$"Control/play?/Panel2/Time".text = "≈" + str(estimated_time) + "min"
	
	
	for i in 3:
		if GameManager.Q1 == i+1:
			Questions[i].self_modulate = Color(0.0, 2.731, 0.0)
		else:
			Questions[i].self_modulate = Color(1.0, 1.0, 1.0)
		if GameManager.Q2 == i+1:
			Questions[i+3].self_modulate = Color(0.0, 2.731, 0.0)
		else:
			Questions[i+3].self_modulate = Color(1.0, 1.0, 1.0)


func _on_play_pressed() -> void:
	if game_name == "Hazelnut fight":
		GameManager.Q1 += 1
		get_tree().change_scene_to_file("res://game/games/hazelnut_fight.tscn")
	elif game_name == "Pizza chess":
		get_tree().change_scene_to_file("res://game/games/pizza_chess.tscn")
	elif game_name == "Gamble":
		get_tree().change_scene_to_file("res://game/games/statistic.tscn")
	elif game_name == "Chess":
		get_tree().change_scene_to_file("res://game/games/chess.tscn")
	elif game_name == "Drawback Chess":
		get_tree().change_scene_to_file("res://game/games/drawback_chess.tscn")
	elif game_name == "Pieces fit":
		get_tree().change_scene_to_file("res://game/games/pieces_fit.tscn")
	elif game_name == "Chess variants":
		if GameManager.Q1 == 16:
			get_tree().change_scene_to_file("res://game/games/chaturaji.tscn")
		elif GameManager.Q1 == 17:
			get_tree().change_scene_to_file("res://game/games/4 player chess.tscn")
		else:
			get_tree().change_scene_to_file("res://game/games/chess_variants.tscn")
	elif game_name == "Connect 4":
		get_tree().change_scene_to_file("res://game/games/connect_4.tscn")
	elif game_name == "Shōgi":
		get_tree().change_scene_to_file("res://game/games/shogi.tscn")
	elif game_name == "Amazons":
		get_tree().change_scene_to_file("res://game/games/amazons.tscn")
	elif game_name == "Castle War":
		if GameManager.Q1 == 3:
			get_tree().change_scene_to_file("res://game/games/giant_castle_war.tscn")
		else:
			get_tree().change_scene_to_file("res://game/games/Castle War.tscn")
	elif game_name == "Better tic tac toe":
		get_tree().change_scene_to_file("res://game/games/tic_tac_toe.tscn")
	elif game_name == "Gomoku":
		get_tree().change_scene_to_file("res://game/games/Gomuku.tscn")
	elif game_name == "Reversi":
		get_tree().change_scene_to_file("res://game/games/reversi.tscn")
	elif game_name == "Tafl games":
		get_tree().change_scene_to_file("res://game/games/talf.tscn")
	elif game_name == "GO":
		get_tree().change_scene_to_file("res://game/games/go.tscn")
	elif game_name == "Lines of action":
		get_tree().change_scene_to_file("res://game/games/lines of action.tscn")
	


func _on_quit_pressed() -> void:
	$"Control/play?".visible = false
	$Control/options.visible = false


func _on_option_pressed() -> void:
	$Control/options.visible = true



# Settings

func _on_no_bots_pressed() -> void:
	GameManager.Bots = 0
	settings()


func _on_normal_bot_pressed() -> void:
	if GameManager.Bots == 0:
		GameManager.Bots = 1
	GameManager.Bots_difficulty = false
	settings()


func _on_hard_bot_pressed() -> void:
	if GameManager.Bots == 0:
		GameManager.Bots = 1
	GameManager.Bots_difficulty = true
	settings()


func _on_1_bot_pressed() -> void:
	if not GameManager.Bots == 0:
		GameManager.Bots = 1
		settings()


func _on_2_bots_pressed() -> void:
	if not GameManager.Bots == 0:
		GameManager.Bots = 2
		settings()


func _on_3_bots_pressed() -> void:
	if not GameManager.Bots == 0:
		GameManager.Bots = 3
		settings()


func _on_reset_victories_pressed() -> void:
	GameManager.PlayerVictory = [0,0,0,0]
	$"Control/victory's".text = "Victory's : P1=" + str(GameManager.PlayerVictory[0]) + " ; P2=" + str(GameManager.PlayerVictory[1]) + " ; P3=" + str(GameManager.PlayerVictory[2]) + " ; P4=" + str(GameManager.PlayerVictory[3])


func _on_reset_all_pressed() -> void:
	GameManager.PlayerVictory = [0,0,0,0]
	$"Control/victory's".text = "Victory's : P1=" + str(GameManager.PlayerVictory[0]) + " ; P2=" + str(GameManager.PlayerVictory[1]) + " ; P3=" + str(GameManager.PlayerVictory[2]) + " ; P4=" + str(GameManager.PlayerVictory[3])

func settings():
	
	if GameManager.Bots == 0:
		$"Control/options/Panel2/Q1/No Bots".modulate = Color(0.0, 1.0, 0.0)
		
		$"Control/options/Panel2/Q1/Normal Bot".modulate = Color(1.0, 1.0, 1.0)
		$"Control/options/Panel2/Q1/Hard Bot".modulate = Color(1.0, 1.0, 1.0)
		$"Control/options/Panel2/Q2/1 Bot".modulate = Color(1.0, 1.0, 1.0)
		$"Control/options/Panel2/Q2/2 Bots".modulate = Color(1.0, 1.0, 1.0)
		$"Control/options/Panel2/Q2/3 Bots".modulate = Color(1.0, 1.0, 1.0)
	else:
		if GameManager.Bots == 1:
			$"Control/options/Panel2/Q2/1 Bot".modulate = Color(0.0, 1.0, 0.0)
			
			$"Control/options/Panel2/Q2/2 Bots".modulate = Color(1.0, 1.0, 1.0)
			$"Control/options/Panel2/Q2/3 Bots".modulate = Color(1.0, 1.0, 1.0)
		elif GameManager.Bots == 2:
			$"Control/options/Panel2/Q2/2 Bots".modulate = Color(0.0, 1.0, 0.0)
			
			$"Control/options/Panel2/Q2/1 Bot".modulate = Color(1.0, 1.0, 1.0)
			$"Control/options/Panel2/Q2/3 Bots".modulate = Color(1.0, 1.0, 1.0)
		elif GameManager.Bots == 3:
			$"Control/options/Panel2/Q2/3 Bots".modulate = Color(0.0, 1.0, 0.0)
			
			$"Control/options/Panel2/Q2/1 Bot".modulate = Color(1.0, 1.0, 1.0)
			$"Control/options/Panel2/Q2/2 Bots".modulate = Color(1.0, 1.0, 1.0)
		
		if GameManager.Bots_difficulty == false:
			$"Control/options/Panel2/Q1/Normal Bot".modulate = Color(0.0, 1.0, 0.0)
			$"Control/options/Panel2/Q1/Hard Bot".modulate = Color(1.0, 1.0, 1.0)
		else:
			$"Control/options/Panel2/Q1/Hard Bot".modulate = Color(0.0, 1.0, 0.0)
			$"Control/options/Panel2/Q1/Normal Bot".modulate = Color(1.0, 1.0, 1.0)
		
		$"Control/options/Panel2/Q1/No Bots".modulate = Color(1.0, 1.0, 1.0)


func _on_boxes_color_changed(color: Color) -> void:
	GameManager.color = color
	SaveManager.content_to_save["box color"] = color
	SaveManager._save()


func _on_background_color_changed(color: Color) -> void:
	$Control/Panel.modulate = color


func _on_text_text_submitted(new_text: String) -> void:
	if not variants.has(new_text):
		var total = []
		total.resize(variants.size())
		total.fill(0)
		for letter in new_text.length():
			for i in variants.size():
				if str(variants[i]).length() > letter:
					if str(str(variants[i])[letter]).to_upper() == str(new_text[letter]).to_upper():
						total[i] += 1
		var biggest = 0
		var closer = []
		for i in total.size():
			if total[i] > biggest:
				biggest = total[i]
				closer = [i]
			elif total[i] == biggest:
				closer.insert(0,i)
		var rng = RandomNumberGenerator.new()
		var respond = rng.randi_range(0,closer.size()-1)
		$"Control/play?/Panel2/text".text = variants[closer[respond]]
		
		
		GameManager.Q1 = closer[respond]
		
		if variants_time[closer[respond]] >= 60:
			$"Control/play?/Panel2/Time".text = "≈" + str(((variants_time[closer[respond]]*100)/60)*0.01) + "h"
		else:
			$"Control/play?/Panel2/Time".text = "≈" + str(variants_time[closer[respond]]) + "min"

func _on_text_editing_toggled(toggled_on: bool) -> void:
	if toggled_on == false:
		_on_text_text_submitted($"Control/play?/Panel2/text".text)

func _on__pressed() -> void:
	$"Control/play?/Possibility".visible = true
	$"Control/play?/Possibility/Panel/Games".visible = true
	$"Control/play?/Possibility/Panel/Details".visible = false


func _on_quit__pressed() -> void:
	$"Control/play?/Possibility".visible = false


func _on_details_pressed() -> void:
	$"Control/play?/Possibility".visible = true
	$"Control/play?/Possibility/Panel/Games".visible = false
	$"Control/play?/Possibility/Panel/Details".visible = true
	if game_name == "Chess variants":
		$"Control/play?/Possibility/Panel/Details".text = variant_details[GameManager.Q1]
	else:
		$"Control/play?/Possibility/Panel/Details".text = details[detail_num]



## PANEL THEMES

var themes = ["Winter","Spring","Summer","Autumn","Openvoxel","Stardance","Chess","Ducks"]

func _on_theme_text_submitted(new_text: String) -> void:
	if new_text == "Openvoxel":
		SaveManager.content_to_save["has_theme"][4] = true
	elif new_text == "Stardance":
		SaveManager.content_to_save["has_theme"][5] = true
	
	var total = []
	total.resize(themes.size())
	total.fill(0)
	for letter in new_text.length():
		for i in themes.size():
			if SaveManager.content_to_save["has_theme"][i] == true:
				if str(themes[i]).length() > letter:
					if str(str(themes[i])[letter]).to_upper() == str(new_text[letter]).to_upper():
						total[i] += 1
	var biggest = 0
	var closer = []
	for i in total.size():
		if SaveManager.content_to_save["has_theme"][i] == true:
			if total[i] > biggest:
				biggest = total[i]
				closer = [i]
			elif total[i] == biggest:
				closer.insert(0,i)
	var rng = RandomNumberGenerator.new()
	var respond = rng.randi_range(0,closer.size()-1)
	$Control/options/Panel2/Theme.text = themes[closer[respond]]

	
	$Control/Panel.texture = Panel_texture[closer[respond]]
	SaveManager.content_to_save["current_theme"] = closer[respond]
	SaveManager._save()


func _on_theme_editing_toggled(toggled_on: bool) -> void:
	if toggled_on == false:
		_on_theme_text_submitted($Control/options/Panel2/Theme.text)


func _on_quit_themes_pressed() -> void:
	$Control/options/Themes.visible = false


func _on_themes_pressed() -> void:
	$Control/options/Themes.visible = true
	
	$Control/options/Themes/Panel/RichTextLabel.text = ""
	for i in themes.size():
		if SaveManager.content_to_save["has_theme"][i] == true:
			$Control/options/Themes/Panel/RichTextLabel.text += themes[i]
		else:
			$Control/options/Themes/Panel/RichTextLabel.text += "unknown"
		$Control/options/Themes/Panel/RichTextLabel.text += "     "


func _input(event: InputEvent) -> void:
	if $Control/options.visible == false and $"Control/play?".visible == false:
		if event.is_action_pressed("shift"):
			$Camera2D.move_local_x(2000)
			$Control/Panel.move_local_x(2000)
		elif event.is_action_released("shift"):
			$Camera2D.global_position = Vector2(576.0,324.0)
			$Control/Panel.global_position = Vector2(576.0,324.0)
		
		
		elif event.is_action_pressed("slide_up"):
			$Control/UI/VSlider.value += 14.5
			_on_v_slider_value_changed($Control/UI/VSlider.value)
		elif event.is_action_pressed("slide_down"):
			$Control/UI/VSlider.value -= 14.5
			_on_v_slider_value_changed($Control/UI/VSlider.value)
		
		elif event.is_action("down"):
			$Control/UI/VSlider.value -= 5
			_on_v_slider_value_changed($Control/UI/VSlider.value)
		elif event.is_action("up"):
			$Control/UI/VSlider.value += 5
			_on_v_slider_value_changed($Control/UI/VSlider.value)




func _on_up_pressed() -> void:
	var order_array = SaveManager.content_to_save["Order"]

	var pos = order_array.find(number)

	if pos == -1 or pos <= 0:
		return

	var temp = order_array[pos]
	order_array[pos] = order_array[pos - 1]
	order_array[pos - 1] = temp

	order()
	SaveManager._save()


func _on_down_pressed() -> void:
	var order_array = SaveManager.content_to_save["Order"]

	var pos = order_array.find(number)

	if pos == -1 or pos >= order_array.size() - 1:
		return

	var temp = order_array[pos]
	order_array[pos] = order_array[pos + 1]
	order_array[pos + 1] = temp

	order()
	SaveManager._save()


func order() -> void:
	var grid = $Control/UI/Games/GridContainer

	var games = [
		grid.get_node_or_null("Chess"),
		grid.get_node_or_null("Drawback chess"),
		grid.get_node_or_null("Shogi"),
		grid.get_node_or_null("chess variants"),
		grid.get_node_or_null("Castle War"),
		grid.get_node_or_null("Tafl"),
		grid.get_node_or_null("Go"),
		grid.get_node_or_null("Connect 4"),
		grid.get_node_or_null("Reversi"),
		grid.get_node_or_null("Pizza Chess"),
		grid.get_node_or_null("Amazons"),
		grid.get_node_or_null("Gomoku"),
		grid.get_node_or_null("Lines of action"),
		grid.get_node_or_null("Pieces fit"),
		grid.get_node_or_null("Gamble"),
		grid.get_node_or_null("Hazelnut")
	]

	var order_array = SaveManager.content_to_save["Order"]

	for i in order_array.size():
		var game_id = order_array[i]

		if game_id < 0 or game_id >= games.size():
			print("Invalid game ID: ", game_id)
			continue

		var game = games[game_id]

		if game == null:
			print("Game node is missing for ID: ", game_id)
			continue

		grid.move_child(game, i)
