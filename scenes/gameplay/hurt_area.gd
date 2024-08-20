extends Area3D

@export var damage_per_second: float = 20
@export var vfx: Node3D
@export var vfx_scale_id_limit: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_vfx_visibility()
	Globals.add_scale_watcher(update_vfx_visibility)

func update_vfx_visibility():
	if vfx == null:
		return
	vfx.visible = Globals.scale_index >= vfx_scale_id_limit

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for area in get_overlapping_areas():
		if area is HurtBoxComponent:
			area.health.take_damage(damage_per_second * delta)
