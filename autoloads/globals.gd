extends Node

signal scale_update()

const SCALES: Array[float] = [2.75, 0.5, 0.1]

var scale_index: int = 0:
	set(new_scale_id):
		scale_index = clampi(new_scale_id, 0, SCALES.size()-1)
		scale = SCALES[scale_index]

var scale: float = SCALES[0]:
	set(new_scale):
		scale = new_scale
		scale_update.emit()

func add_scale_watcher(callable: Callable):
	scale_update.connect(callable)

func clean_scale_watchers():
	for connection: Dictionary in scale_update.get_connections():
		scale_update.disconnect(connection["callable"])

func scale_up():
	scale_index -= 1

func scale_down():
	scale_index += 1
