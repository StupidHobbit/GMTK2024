extends RayCast3D

@export var interaction_buffer_time = 0.3
var buffered_interactable: Interactable
var time_from_last_interact_press: float
var time_from_last_interactable: float

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
		
	time_from_last_interact_press += delta
	time_from_last_interactable += delta
		
	var interactable = get_interactable()
	if interactable != null:
		time_from_last_interactable = 0
	if interactable == null and time_from_last_interactable < interaction_buffer_time:
		interactable = buffered_interactable
	
	if interactable == null or not interactable.enabled:
		hide_message()
		return
	buffered_interactable = interactable
	var label = interactable.get_label()
	if label == "":
		hide_message()
		return
	
	interactable.on_hover()
	show_message(label)
	
	if Input.is_action_just_pressed("interact"):
		time_from_last_interact_press = 0
	
	if time_from_last_interact_press < interaction_buffer_time:
		interactable.on_interact(character)
		time_from_last_interact_press = interaction_buffer_time
		buffered_interactable = null
	

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
