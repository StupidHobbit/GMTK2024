extends CharacterBody3D

class_name Character

# Constants

@export var SPEED = 4.0
@export var RUNNING_SPEED = 10.0
@export var SPEED_DAMPING = 4.0
@export var CROUCHING_SPEED = 4.0
@export var CROUCHING_DELTA = 0.5
@export var CROUCHING_BOOST_SPEED = 13.0
@export var CROUCHING_BOOST_COOLDOWN = 5.0
@export var JUMP_VELOCITY = 6
@export var DASH_VELOCITY = 20
@export var LAUNCHPAD_TIME = 1
@export var jumping_gravity: float = 15
@export var falling_gravity: float = 30
@export var pad_gravity: float = 30
@export var jump_buffer: float = 0.1
@export var coyote_time: float = 0.1
@export var climbing_time_limit: float = 0.1
@export var climbing_speed: float = 4
@export var slowdown_time: float = 0.1
@export var crouching_animation_time: float = 0.2
@export var current_checkpoint: CheckPoint

@export var scales: Array[float] = [1, 0.5, 0.25, 0.1]
var scale_index: int = 0

var time_from_last_jump_press: float = 100 
var time_from_last_on_floor: float = 0 
var time_from_last_crouching_boost: float = 0 
var climbing_time: float = 1
var turn = Vector2(0, 0)
var viewport_size: Vector2
var movement_disabled: bool = false
var has_crouching_boost: bool = false
var has_dash_boost: bool = false
var handle_input: bool = true
var is_falling: bool = false
var examinated_item: Examinable
var original_camera_near: float
var original_interact_length: float

# variables for ledge climbing

var ledge_climbing: bool = false
var lc_dest: Vector3
var lc_start: Vector3
var lc_anim_time: float = 1

# variables for launchpads

var launchpads: Array[LaunchPad] = []
var launchpad_timer: float = 0

# speed lines

var SPEEDLINE_LIMIT_LOW = 15
var SPEEDLINE_LIMIT_HIGH = 20
var SPEEDLINE_MAX_ALPHA = 0.3

# children shortcuts

@onready var camera = $Camera3D
@onready var holder = $Camera3D/Holder
@onready var anim_component = $character_animation
@onready var walk_audio_stream_player = $WalkAudioStreamPlayer
@onready var jump_audio_player = $JumpAudioPlayer
@onready var fall_audio_player = $FallAudioPlayer
@onready var interact: RayCast3D = $Camera3D/Interact2
@onready var health_component: HealthComponent = $HealthComponent


var current_scale: float:
	get:
		return scale[0]
	set(value):
		scale = Vector3(value, value, value)

func on_scale_update():
	current_scale = Globals.scale
	camera.near = original_camera_near * Globals.scale
	interact.target_position.z = original_interact_length * Globals.scale

func _ready():
	Globals.add_scale_watcher(on_scale_update)
	viewport_size = get_viewport().size / 2
	original_camera_near = camera.near
	original_interact_length = interact.target_position.z
	
	health_component.health_depleted.connect(on_health_depleted)
	
	start_handle_input()
	Globals.scale = current_scale

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
	if ledge_climbing:
		climb(delta)
		apply_rotation()
		return
	update_scale()
	if movement_disabled:
		return
	apply_vertical_movement(delta)
	apply_rotation()
	#apply_crouching(delta)
	apply_horizontal_movement(delta)
	apply_dash(delta)
	move_and_slide()
	launchpad_timer = max(0, launchpad_timer - delta)
	
	var speedline_weight = inverse_lerp(
		SPEEDLINE_LIMIT_LOW * Globals.scale,
		SPEEDLINE_LIMIT_HIGH * Globals.scale,
		velocity.length()
	)
	speedline_weight = clamp(speedline_weight, 0, 1)
	$Speedlines.modulate.a = lerp(0.0, SPEEDLINE_MAX_ALPHA, speedline_weight)

func climb(delta: float):
	var dir = lc_dest - lc_start
	var rel_dist = (position - lc_start).length() / dir.length()
	var rel_delta = delta / lc_anim_time
	
	if rel_dist + rel_delta > 1:
		# end of ledge climbing
		position = lc_dest
		ledge_climbing = false
		return
	
	position += dir * rel_delta

func apply_vertical_movement(delta: float):
	var jump_just_pressed = Input.is_action_just_pressed("jump")
	
	var jump_pressed = Input.is_action_pressed("jump")
	
	var on_floor = is_on_floor()
	if on_floor:
		if is_falling:
			fall_audio_player.play()
		is_falling = false
		time_from_last_on_floor = 0
		climbing_time = 0
	time_from_last_on_floor += delta
	
	if not on_floor:
		is_falling = true
		if is_climbing(jump_pressed):
			velocity.y = climbing_speed * current_scale
			climbing_time += delta
		
		var gravity
		if launchpad_timer > 0:
			gravity = pad_gravity
		elif velocity.y > 0 and jump_pressed:
			gravity = jumping_gravity
		else:
			gravity = falling_gravity
		
		velocity.y -= gravity * delta * current_scale

	if jump_just_pressed and time_from_last_jump_press > jump_buffer and time_from_last_on_floor < coyote_time:
		if launchpad_timer <= 0:
			apply_launchpads()
		velocity.y = max(velocity.y, JUMP_VELOCITY * current_scale)
		
		if not jump_audio_player.playing:
			jump_audio_player.play()
	
	if jump_just_pressed:
		time_from_last_jump_press = 0
	time_from_last_jump_press += delta

func apply_rotation():
	var rot = turn * PI / viewport_size
	global_rotation = Vector3(global_rotation.x, -rot.x, 0)
	camera.rotation = Vector3(-rot.y, 0, 0)

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
		var damping
		
		anim_component.move()
		var dir: Vector3 = Vector3(velocity.x, 0, velocity.z)
		var cur_speed: float = dir.length()
		dir = dir.normalized()
		if cur_speed > speed:
			if is_on_floor():
				cur_speed = move_toward(cur_speed, speed, SPEED_DAMPING * delta)
				velocity.x = dir.x * cur_speed
				velocity.z = dir.z * cur_speed
		else:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
	else:
		anim_component.be_idle()
		if is_on_floor():
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
	
func update_scale():
	if Input.is_action_just_pressed("scale_down"):
		scale_index += 1
	elif Input.is_action_just_pressed("scale_up"):
		scale_index -= 1
	else:
		return
	scale_index = clampi(scale_index, 0, len(scales) - 1)
	Globals.scale = scales[scale_index]

func on_health_depleted():
	if current_checkpoint == null:
		return
	position = current_checkpoint.position 

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
	return _get_current_speed_without_scale() * current_scale
	
func _get_current_speed_without_scale() -> float:
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

func on_pad_entered(area: LaunchPad) -> void:
	launchpads.append(area)

func on_pad_exited(area: LaunchPad) -> void:
	launchpads.erase(area)

func apply_launchpads() -> void:
	if launchpads.size() == 0:
		return
	
	if scale_index < 2:
		# disabled for big sizes
		return
	
	print("launching!")
	
	var dir: Vector3 = Vector3.ZERO
	for pad: LaunchPad in launchpads:
		dir += pad.dir
	
	velocity = 20 * Globals.scale * dir / launchpads.size()
	launchpad_timer = LAUNCHPAD_TIME
