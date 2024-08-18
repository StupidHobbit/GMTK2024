extends Area3D

@export var damage_per_second: float = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for area in get_overlapping_areas():
		if area is HurtBoxComponent:
			area.health.take_damage(damage_per_second * delta)
