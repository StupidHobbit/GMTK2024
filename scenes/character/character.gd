extends CharacterBody3D

class_name Character

@export var SPEED = 4.0
@export var RUNNING_SPEED = 10.0
@export var SPEED_DAMPING = 4.0
@export var CROUCHING_SPEED = 4.0
@export var CROUCHING_DELTA = 0.5
@export var CROUCHING_BOOST_SPEED = 13.0
@export var CROUCHING_BOOST_COOLDOWN = 5.0
@export var JUMP_VELOCITY = 6
@export var DASH_VELOCITY = 20
@export var jumping_gravity: float = 15
@export var falling_gravity: float = 30
@export var jump_buffer: float = 0.1
@export var coyote_time: float = 0.1
@export var climbing_time_limit: float = 0.5
@export var climbing_speed: float = 4
@export var slowdown_time: float = 0.1
@export var crouching_animation_time: float = 0.2

var time_from_last_jump_press: float = 100 
var time_from_last_on_floor: float = 0 
var time_from_last_crouching_boost: float = 0 
var climbing_time: float = 0.5
var turn = Vector2(0, 0)
var viewport_size: Vector2
var movement_disabled: bool = false
var has_crouching_boost: bool = false
var has_dash_boost: bool = false
var handle_input: bool = true
var is_falling: bool = false
var examinated_item: Examinable

@onready var camera = $Camera3D
@onready var holder = $Camera3D/Holder
@onready var anim_component = $character_animation
@onready var walk_audio_stream_player = $WalkAudioStreamPlayer
@onready var jump_audio_player = $JumpAudioPlayer
@onready var fall_audio_player = $FallAudioPlayer


func _ready():
	viewport_size = get_viewport().size / 2

	start_handle_input()
	

func start_handle_input():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	handle_input = true
	movement_disabled = false
	
func stop_handle_input():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	handle_input = false
	movement_disabled = true

func examine(item: Examinable, collision_rid: RID):
	item.reparent(holder)
	if collision_rid.is_valid():
		holder.add_excluded_object(collision_rid)
	examinated_item = item
	disable_movement()

func _physics_process(delta: float):
	update_examination()
	if movement_disabled:
		return
	apply_vertical_movement(delta)
	apply_rotation()
	#apply_crouching(delta)
	apply_horizontal_movement(delta)
	apply_dash(delta)
	move_and_slide()

func apply_vertical_movement(delta: float):
	var jump_just_pressed = Input.is_action_just_pressed("jump")
	if jump_just_pressed:
		time_from_last_jump_press = 0
	time_from_last_jump_press += delta
	
	var jump_pressed = Input.is_action_pressed("jump")
	var is_on_floor = is_on_floor()
	if is_on_floor:
		if is_falling:
			fall_audio_player.play()
		is_falling = false
		time_from_last_on_floor = 0
		climbing_time = 0
	time_from_last_on_floor += delta
	
	if not is_on_floor:
		is_falling = true
		if is_climbing(jump_pressed):
			velocity.y = climbing_speed
			climbing_time += delta
		
		var gravity = jumping_gravity if velocity.y > 0 and jump_pressed else falling_gravity
		velocity.y -= gravity * delta

	if time_from_last_jump_press < jump_buffer and time_from_last_on_floor < coyote_time:
		velocity.y = JUMP_VELOCITY
		jump_audio_player.play()

func apply_rotation():
	var rotation = turn * PI / viewport_size
	global_rotation = Vector3(global_rotation.x, -rotation.x, 0)
	camera.rotation = Vector3(-rotation.y, 0, 0)

func apply_crouching(delta: float):
	time_from_last_crouching_boost -= delta
	if Input.is_action_just_pressed("crouch") and time_from_last_crouching_boost <= 0:
		has_crouching_boost = true
	
	var to = 0
	
	if is_crouching():
		to = -CROUCHING_DELTA
	camera.position.y = move_toward(camera.position.y, to, CROUCHING_DELTA * delta / crouching_animation_time)

func apply_horizontal_movement(delta: float):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed = get_current_speed()

	walk_audio_stream_player.pitch_scale = 1.2 + 0.8 * speed / RUNNING_SPEED
	if direction and is_on_floor():
		if not walk_audio_stream_player.playing:
			walk_audio_stream_player.play()
	elif walk_audio_stream_player.playing:
		walk_audio_stream_player.stop()
	
	if direction:
		var actual_horizontal_speed = _get_actual_horizontal_speed()
		if actual_horizontal_speed > speed:
			speed = move_toward(actual_horizontal_speed, speed, SPEED_DAMPING * delta)
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if is_on_floor():
			anim_component.move()
	else:
		anim_component.be_idle()
		velocity.x = move_toward(velocity.x, 0, speed * delta / slowdown_time)
		velocity.z = move_toward(velocity.z, 0, speed * delta / slowdown_time)
	
func apply_dash(delta: float):
	if not has_dash_boost:
		return
	#velocity += interact.force_raycast_update().normalized() * DASH_VELOCITY
	has_dash_boost = false

func _get_actual_horizontal_speed() -> float:
	return sqrt(velocity.x ** 2 + velocity.z ** 2)

func update_examination():
	if examinated_item == null or Input.is_action_pressed("interact"):
		return
	examinated_item.put_back()
	examinated_item = null
	enable_movement()
	holder.clear_excluded_objects()

func is_crouching()  -> bool:
	return Input.is_action_pressed("crouch")

func is_running() -> bool:
	return Input.is_action_pressed("run")

func is_climbing(jump_pressed: bool) -> bool:
	return climbing_time <= climbing_time_limit and jump_pressed and is_on_wall()
	
func disable_movement():
	movement_disabled = true

func enable_movement():
	movement_disabled = false

func dash():
	has_dash_boost = true

func get_current_speed() -> float:
	if has_crouching_boost and is_on_floor():
		has_crouching_boost = false
		time_from_last_crouching_boost = CROUCHING_BOOST_COOLDOWN
		return CROUCHING_BOOST_SPEED
	if is_crouching():	
		return CROUCHING_SPEED
	if is_running():
		return RUNNING_SPEED
	return SPEED

func _process(delta: float):
	pass

func _input(event: InputEvent):
	if not handle_input:
		return
	if event is InputEventMouseMotion:
		if examinated_item != null:
			examinated_item.rotation.x += event.relative.y * PI / viewport_size.y
			examinated_item.rotation.y += event.relative.x * PI / viewport_size.x
			return
			
		turn += event.relative
	turn.y = clampf(turn.y, -viewport_size.y / 2, viewport_size.y / 2)
	
	
