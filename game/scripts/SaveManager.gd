extends Node

const save_location = "user://SaveFile.json"


const has_theme_size = 8
var content_to_save : Dictionary = {
	"has_theme" = [false,false,false,false,false,false,false,false],
	"current_theme" = 0,
	"box color" = Color(1.0, 0.333, 0.631),
	"Order" = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
}

func _ready() -> void:
	_load()

func _save():
	var file = FileAccess.open(save_location, FileAccess.WRITE)
	file.store_var(content_to_save.duplicate())
	file.close()
	

func _load():
	if FileAccess.file_exists(save_location):
		var file = FileAccess.open(save_location, FileAccess.READ)
		var data = file.get_var()
		file.close()
		
		var save_data = data.duplicate()
		content_to_save["has_theme"] = save_data["has_theme"]
		content_to_save["current_theme"] = save_data["current_theme"]
		content_to_save["box color"] = save_data["box color"]
		content_to_save["Order"] = save_data["Order"]
		
		if content_to_save["has_theme"].size() < has_theme_size:
			while content_to_save["has_theme"].size() < has_theme_size:
				content_to_save["has_theme"].insert(content_to_save["has_theme"].size(), false)
