extends CanvasLayer

func level(num):
	$CurrentLevel.text = "Level: "  +str(num)
	
func gems(num):
	$gemslabel.text = "Gems: "  +str(num)
