extends Node3D

class_name Interactable

@export var enabled: bool = true

func get_label() -> String:
	return "Interact"

func on_interact(character: Character):
	pass
