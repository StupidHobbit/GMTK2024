extends Interactable

signal end_level()

func can_interact(player: Character) -> bool:
	return true

func on_hover():
	pass

func get_label() -> String:
	return "Exit the room"

func on_interact(_player: Character):
	end_level.emit()
