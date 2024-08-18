extends Area3D

@export var damage_per_second: float = 20
@export var vfx: Node3D
@export var vfx_scale_limit: float = 0.8

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_vfx_sisibility()
	Globals.add_scale_watcher(update_vfx_sisibility)

func update_vfx_sisibility():
	if vfx == null:
		return
	vfx.visible = Globals.scale < vfx_scale_limit

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for area in get_overlapping_areas():
		if area is HurtBoxComponent:
			area.health.take_damage(damage_per_second * delta)
