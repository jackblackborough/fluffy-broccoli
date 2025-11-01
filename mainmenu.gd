extends Node2D



func _ready() -> void:
	print("main menu ready")
	$StartButton.grab_focus()



func _on_start_button_pressed() -> void:
	print("Start button pressed")
	get_tree().change_scene_to_file("res://level_1.tscn")





func _on_button_pressed() -> void:
	get_tree().quit()
