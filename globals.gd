extends Node

signal scale_update()

var scale: float = 1:
	set(new_scale):
		scale = new_scale
		scale_update.emit()
# 1 is base scale

func add_scale_watcher(callable: Callable):
	scale_update.connect(callable)

func clean_scale_watchers():
	for connection: Dictionary in scale_update.get_connections():
		scale_update.disconnect(connection["callable"])
