extends CharacterBody3D

class_name Character

# Constants

@export var SPEED = 4.0
@export var RUNNING_SPEED = 10.0
@export var SPEED_DAMPING = 4.0
@export var CROUCHING_SPEED = 4.0
@export var ZIPLINE_SPEED = 15.0
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
@export var crouching_scale = 0.5

var change_direction_dot_limit = 0.9

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
var original_camera_height: float

# variables for zipline
var current_zipline: Zipline

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
var SPEEDLINE_MAX_ALPHA = 1.0

# children shortcuts

@onready var camera: Camera3D = $Camera3D
@onready var holder = $Camera3D/Holder
@onready var anim_component = $character_animation
@onready var walk_audio_stream_player = $WalkAudioStreamPlayer
@onready var jump_audio_player = $JumpAudioPlayer
@onready var fall_audio_player = $FallAudioPlayer
@onready var interact: RayCast3D = $Camera3D/Interact2
@onready var health_component: HealthComponent = $HealthComponent
@onready var lp_image = $Camera3D/Interact2/Control/LaunchPadIndicator
@onready var speedlines = $Camera3D/Interact2/Control/SpeedLines

var height: float:
	get():
		return $Camera3D.position.y

func reset(new_pos: Vector3) -> void:
	position = new_pos
	velocity = Vector3.ZERO
	current_zipline = null

func on_scale_update():
	scale = Vector3(Globals.scale, Globals.scale, Globals.scale)
	camera.near = original_camera_near * Globals.scale
	interact.target_position.z = original_interact_length * Globals.scale
	update_launchpad_image()

func _ready():
	Globals.add_scale_watcher(on_scale_update)
	viewport_size = get_viewport().size / 2
	original_camera_near = camera.near
	original_interact_length = interact.target_position.z
	original_camera_height = camera.position.y
	
	health_component.health_depleted.connect(on_health_depleted)
	
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
	update_scale()
	if movement_disabled:
		return
	apply_rotation()
	
	if Input.is_action_just_pressed("jump"):
		stop_zipline()
	
	if ledge_climbing:
		apply_ledge_climbing(delta)
	elif current_zipline != null:
		apply_zipline_move(delta)
		move_and_slide()
	else:
		apply_vertical_movement(delta)
		apply_horizontal_movement(delta)
		apply_crouching(delta)
		move_and_slide()
	launchpad_timer = max(0, launchpad_timer - delta)
	
	var speedline_weight = inverse_lerp(
		SPEEDLINE_LIMIT_LOW * Globals.scale,
		SPEEDLINE_LIMIT_HIGH * Globals.scale,
		velocity.length()
	)
	speedline_weight = clamp(speedline_weight, 0, 1)
	speedlines.modulate.a = lerp(0.0, SPEEDLINE_MAX_ALPHA, speedline_weight)

func apply_ledge_climbing(delta: float):
	var dir = lc_dest - lc_start
	var rel_dist = (position - lc_start).length() / dir.length()
	var rel_delta = delta / lc_anim_time
	
	if rel_dist + rel_delta > 1:
		# end of ledge climbing
		position = lc_dest
		ledge_climbing = false
		return
	
	position += dir * rel_delta

func start_zipline(zipline: Zipline):
	stop_zipline()
	current_zipline = zipline
	walk_audio_stream_player.stop()

func apply_zipline_move(delta: float):
	var camera_direction = -camera.global_transform.basis.z
	var zipline_start_position = current_zipline.start_point.global_position
	var zipline_end_position = current_zipline.end_point.global_position
	var zipline_start_direction = zipline_start_position  - global_position
	var zipline_end_direction = zipline_end_position - global_position
	var target_position = zipline_start_position
	if camera_direction.angle_to(zipline_start_direction) > camera_direction.angle_to(zipline_end_direction):
		target_position = zipline_end_position
	
	var target_vector = target_position - global_position
	if target_vector.length() < Globals.scale * 0.3:
		stop_zipline()
		velocity = Vector3.ZERO
		return
		
	velocity = target_vector.normalized() * ZIPLINE_SPEED
	
func stop_zipline():
	if current_zipline == null:
		return
	time_from_last_on_floor = 0
	current_zipline.stop_player_travel()
	current_zipline = null

func apply_vertical_movement(delta: float):
	var jump_just_pressed = Input.is_action_just_pressed("jump")
	
	if jump_just_pressed:
		time_from_last_jump_press = 0
	time_from_last_jump_press += delta
	
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
			velocity.y = climbing_speed * Globals.scale
			climbing_time += delta
		
		var gravity
		if launchpad_timer > 0:
			gravity = pad_gravity
		elif velocity.y > 0 and jump_pressed:
			gravity = jumping_gravity
		else:
			gravity = falling_gravity
		
		velocity.y -= gravity * delta * Globals.scale
	
	if Globals.scale_index > 0 and time_from_last_jump_press < jump_buffer:
		var jumped: bool = false
		
		if launchpad_timer <= 0:
			apply_launchpads()
			jumped = true
		
		if time_from_last_on_floor < coyote_time:
			velocity.y = max(velocity.y, JUMP_VELOCITY * Globals.scale)
			jumped = true
		
		if jumped and not jump_audio_player.playing:
			jump_audio_player.play()

func apply_rotation():
	var rot = turn * PI / viewport_size
	global_rotation = Vector3(global_rotation.x, -rot.x, 0)
	camera.rotation = Vector3(-rot.y, 0, 0)

func apply_crouching(delta: float):
	time_from_last_crouching_boost -= delta
	if Input.is_action_just_pressed("crouch") and time_from_last_crouching_boost <= 0:
		has_crouching_boost = true
	
	var to = original_camera_height
	
	if is_crouching():
		to = original_camera_height * crouching_scale
	camera.position.y = move_toward(camera.position.y, to, original_camera_height * (1 - crouching_scale) * delta / crouching_animation_time)

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
		anim_component.move()
		var current_velocity: Vector3 = Vector3(velocity.x, 0, velocity.z)
		var current_direction: Vector3 = current_velocity.normalized()
		var cur_speed: float = max(current_velocity.length(), speed)
		var dot = direction.dot(current_direction)
		var new_horizontal_velocity: Vector3
		if is_on_floor():
			if cur_speed > speed:
				cur_speed = move_toward(cur_speed, speed, SPEED_DAMPING * delta)
			if dot < change_direction_dot_limit:
				new_horizontal_velocity = direction * speed
			else:
				new_horizontal_velocity = direction * cur_speed
		else:
			if current_velocity and dot < change_direction_dot_limit:
				new_horizontal_velocity = current_velocity
			else:
				new_horizontal_velocity = direction * cur_speed
		velocity.x = new_horizontal_velocity.x
		velocity.z = new_horizontal_velocity.z
	else:
		anim_component.be_idle()
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, speed * delta / slowdown_time)
			velocity.z = move_toward(velocity.z, 0, speed * delta / slowdown_time)

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
		Globals.scale_down()
	elif Input.is_action_just_pressed("scale_up"):
		Globals.scale_up()
	else:
		return

func on_health_depleted():
	if current_checkpoint == null:
		return
	
	health_component.reset()
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

func get_current_speed() -> float:
	return _get_current_speed_without_scale() * Globals.scale
	
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
	# for web build to properly capture the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
	update_launchpad_image()

func on_pad_exited(area: LaunchPad) -> void:
	launchpads.erase(area)
	update_launchpad_image()

func update_launchpad_image():
	for pad in launchpads:
		if pad.can_launch(self):
			lp_image.show()
			return
	lp_image.hide()

func apply_launchpads() -> void:
	#print("start apply launchpads")
	
	var dir: Vector3 = Vector3.ZERO
	var count: int = 0
	for pad: LaunchPad in launchpads:
		if not pad.can_launch(self): continue
		dir += pad.dir
		count += 1
		pad.play_anim()
	
	if count == 0:
		#print("no launchpads")
		return
	
	#print("launching!")
	
	velocity = 20 * Globals.scale * dir / count
	launchpad_timer = LAUNCHPAD_TIME
