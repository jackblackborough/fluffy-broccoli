extends Node2D

@export var level_num = 0

func _ready() -> void:
	$HUD.level(level_num)
	set_gems_label()
	for gem in $Gems.get_children():
		gem.gem_collected.connect(_on_gem_gem_collected)



func _on_gem_gem_collected() -> void:
	set_gems_label()



func set_gems_label():
	$HUD.gems(Global.gems_collected)

func _on_door_player_entered(level: Variant) -> void:
	get_tree().change_scene_to_file(level)


func _input(event):
	if event.is_action_pressed("reset_level"):
		get_tree().reload_current_scene()
