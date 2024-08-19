extends Interactable

class_name ZiplinePart

var zipline: Zipline

func get_label() -> String:
	return "Zipline"

func on_hover():
	pass

func can_interact(player: Character) -> bool:
	return zipline.current_player == null

func on_interact(player: Character):
	zipline.start_player_travel(player)
