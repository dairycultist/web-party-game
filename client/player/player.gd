extends CharacterBody2D

var is_local: bool

# automatically populated when player is instanced
var player_id: int
var player_username: String

func _enter_tree() -> void:
	
	# give the correct player authority
	set_multiplayer_authority(player_id)
	
	# if player is on the server, make it invisible + uninteractable
	# as to not mess with the local client
	if multiplayer.is_server():
		visible = false
		collision_layer = 0
		collision_mask = 0
		return
	
	$Username.text = player_username
	
	# identify if this is the local player
	is_local = player_id == multiplayer.get_unique_id()

func _physics_process(_delta: float) -> void:
	
	if not is_local:
		return
		
	var move := Vector2.ZERO

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		move = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	
	velocity = 100.0 * move

	move_and_slide()
