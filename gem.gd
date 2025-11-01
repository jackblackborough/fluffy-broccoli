extends Node2D

signal gem_collected

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.gems_collected += 1
		gem_collected.emit()
		$coinSfx.play()
		hide()


func _on_coin_sfx_finished() -> void:
	queue_free()
