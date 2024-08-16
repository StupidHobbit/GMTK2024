extends Node

class_name CharacterAnimation

@export var animation_player: AnimationPlayer

enum MovementState {Jumping, Walking, Idle}
enum SpellState {None, Preparing, Prepared}

var movement_state: MovementState = MovementState.Idle

func be_idle():
	movement_state = MovementState.Idle

func move():
	movement_state = MovementState.Walking
	
func jump():
	movement_state = MovementState.Jumping

	
func _process(delta: float):
	animation_player.play(MovementStateToAnimation[movement_state])
	
		
const MovementStateToAnimation = {
	MovementState.Walking: "move",
	MovementState.Jumping: "jump",
	MovementState.Idle: "idle",
}
