extends Area3D
class_name Interactable

@export var enabled: bool = true

func can_interact(player: Character) -> bool:
	return true

func on_hover():
	pass

func get_label() -> String:
	return "Interact"

func on_interact(player: Character):
	pass
