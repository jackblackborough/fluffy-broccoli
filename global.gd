extends Node


var gems_collected = 0


func _ready():
	print_debug("global ready!")
	print_debug("gems collected")
	
	
func _input(event):
	if event.is_action_pressed("return_to_main_menu"):
		print("return to main menu action pressed")
		get_tree().change_scene_to_file("res://Mainmenu.tscn")
