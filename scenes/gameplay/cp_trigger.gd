extends Area3D

signal checkpoint_activated(cp: CheckPoint)

func on_body_entered(body: Node3D) -> void:
	if is_node_ready():
		checkpoint_activated.emit($CheckPoint)
