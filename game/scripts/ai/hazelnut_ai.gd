extends Node

@export var grid = []
@export var not_go_pos = []

var rng = RandomNumberGenerator.new()


func find_best_move(pos,turn):
	
	var possibilitys = []
	var other = []
	var last_resort = []
	
	if not not_go_pos.has(pos[turn-1]):
		not_go_pos += [pos[turn-1]]
	
	for i in 3:
		for j in 3:
			if (not i == 1 and j == 1) or (not ((i == 0 or i == 2) and (j == 0 or j == 2))):
				if pos[turn-1].x + (i -1) <= 6 and pos[turn-1].x + (i -1) >= 1 and pos[turn-1].y + (j -1) <= 6 and pos[turn-1].y + (j -1) >= 1:
					
					if not_go_pos.has(Vector2(pos[turn-1].x + (i -1),(pos[turn-1].y + (j -1)))):
						last_resort += [Vector2(pos[turn-1].x + (i -1),pos[turn-1].y + (j -1))]
					
					else:
						if grid[pos[turn-1].x + (i -1) + (pos[turn-1].y + (j -1) * 6)] == "forest":
							possibilitys += [Vector2(pos[turn-1].x + (i -1),pos[turn-1].y + (j -1))]
							
						other += [Vector2(pos[turn-1].x + (i -1),pos[turn-1].y + (j -1))]
	
	if possibilitys == []:
		if other == []: return last_resort.pick_random()
		else: return other.pick_random()
	return possibilitys.pick_random()
