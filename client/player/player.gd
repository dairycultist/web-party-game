extends CharacterBody2D

var is_local: bool

var time_since_grounded: float # coyote time
var launch_time: float # disables input and drag for when you're flying in the air from a bouncepad

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

func _physics_process(delta: float) -> void:
	
	if not is_local:
		return

	if launch_time > 0.3:
		
		var move: float
		
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			
			move = Input.get_axis("move_left", "move_right")
			
			if move:
				velocity.x = lerp(velocity.x, 300.0 * move, 12.0 * delta)
		
		if not move:
			velocity.x = lerp(velocity.x, 0.0, 12.0 * delta)
	
	launch_time += delta
	
	# gravity
	velocity.y += 1200.0 * delta
	
	if time_since_grounded < 0.2 and Input.is_action_pressed("jump"):
		velocity.y = -500.0
		time_since_grounded = 0.2
	
	var prev_velocity := velocity

	move_and_slide()
	
	if is_on_wall():
		velocity = prev_velocity - get_wall_normal() * prev_velocity.dot(get_wall_normal())
	
	if is_on_floor():
		velocity = prev_velocity - get_floor_normal() * prev_velocity.dot(get_floor_normal())
		time_since_grounded = 0.0
	else:
		time_since_grounded += delta
