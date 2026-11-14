extends CharacterBody2D

# wario ware, move or die, duck game...

var is_local: bool

var players_node: Node2D
var riders: Array[CharacterBody2D]

var camera: Camera2D

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
	
	if is_local:
		camera = Network.client_node.get_node("Camera")
		camera.target = self

func _ready() -> void:
	
	players_node = get_parent()
	
	if not is_local:
		return
	
	# if we detect another player standing on us, add them to a list of riders
	$RiderDetector.body_entered.connect(func (body: Node2D):
		
		if body is CharacterBody2D and body != self:
			riders.push_back(body)
	)
	
	$RiderDetector.body_exited.connect(func (body: Node2D):
		
		if riders.has(body):
			riders.remove_at(riders.find(body))
	)

func _physics_process(delta: float) -> void:
	
	if not is_local:
		return

	if launch_time > 0.3:
		
		var move: float
		
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			
			move = Input.get_axis("move_left", "move_right")
			
			if move:
				# accelerate faster on a wall to climb up 2 tile ledges
				velocity.x = lerp(velocity.x, (1000.0 if is_on_wall() else 300.0) * move, 6.0 * delta)
		
		if not move:
			velocity.x = lerp(velocity.x, 0.0, 6.0 * delta)
	
	launch_time += delta
	
	if velocity.x < -1:
		$Sprite.flip_h = true
	elif velocity.x > 1:
		$Sprite.flip_h = false
	
	# animation
	if is_on_floor():
		$AnimationPlayer.current_animation = "idle" if abs(velocity.x) < 4.0 else "run"
		$AnimationPlayer.speed_scale = pow(abs(velocity.x) / 300.0, 0.2)
	else:
		$AnimationPlayer.current_animation = "jump"
	
	# gravity
	velocity.y += 1200.0 * delta
	
	# jump
	if time_since_grounded < 0.2 and Input.is_action_pressed("jump"):
		velocity.y = -500.0
		time_since_grounded = 0.2
	
	# move and redirect velocity along normal
	var prev_velocity := velocity

	# before moving, temporarily turn off the collision of all riders so we
	# don't hit them when jumping
	for rider in riders:
		rider.collision_layer = 0

	move_and_slide()
	
	# reenable the collision of riders, and place them directly on top of us
	# (networking may have synced their y to put them where is now inside of us)
	for rider in riders:
		rider.collision_layer = 1
		rider.global_position.y = global_position.y - 38
	
	if is_on_wall():
		velocity = prev_velocity - get_wall_normal() * prev_velocity.dot(get_wall_normal())
	
	if is_on_floor():
		velocity = prev_velocity - get_floor_normal() * prev_velocity.dot(get_floor_normal())
		time_since_grounded = 0.0
	else:
		time_since_grounded += delta
