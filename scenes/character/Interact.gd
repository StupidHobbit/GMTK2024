extends RayCast3D

var input_cleanup_regex = RegEx.new()
var character: Character

func _init():
	input_cleanup_regex.compile("^[\\w ]+")
	
func _ready():
	character = get_parent().get_parent()

func get_interactable() -> Interactable:
	var collider: Interactable = get_collider()
	if collider == null:
		return null
	
	if collider.has_method("can_interact"):
		if not collider.can_interact(character):
			# so that some objects can have conditions
			return null
	
	return collider
	
func _process(delta):
	if not character.handle_input:
		return
	var interactable = get_interactable()
	
	if interactable == null or not interactable.enabled:
		hide_message()
		return
	var label = interactable.get_label()
	if label == "":
		hide_message()
		return
	
	interactable.on_hover()
	show_message(label)
	
	if Input.is_action_just_pressed("interact"):
		interactable.on_interact(character)

func show_message(msg: String, key: String = ""):
	if key == "":
		key = get_interact_input_as_text()
	
	$Control/Label.show()
	$Control/Label.text = "{0}: {1}".format([key, msg])

func hide_message():
	$Control/Label.hide()

func get_interact_input_as_text() -> String:
	var raw = InputMap.action_get_events("interact")[0].as_text()
	var result = input_cleanup_regex.search(raw)
	if result:
		return result.get_string()
	return "Unknown"
