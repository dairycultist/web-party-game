extends CharacterBody2D

var is_local: bool

var players_node: Node2D
var riders: Array[CharacterBody2D]
var riding: CharacterBody2D

@export var x_position: float
@export var x_riding_position: float
@export var y_position: float
# technically, y_riding_position is always -38

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
	
	# decorate the player for the client!
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
	
	# if we land on another player, tell their client to add us to their list of riders
	# and to update our remote player to be riding them
	$RidingDetector.body_entered.connect(func (body: Node2D):
		
		if body is CharacterBody2D and body != self:
			riding = body
			# we also send the x_riding_position in the rpc so that it doesn't
			# use the old value before we can get the new value to it
			x_riding_position = global_position.x - riding.global_position.x
			body._add_player_as_rider.rpc_id(body.player_id, get_path(), x_riding_position)
	)
	
	# similar for when we get off of them
	$RidingDetector.body_exited.connect(func (body: Node2D):
		
		if body is CharacterBody2D and body != self:
			riding = null
			body._remove_player_as_rider.rpc_id(body.player_id, get_path())
	)

@rpc("any_peer", "call_remote", "reliable", 0)
func _add_player_as_rider(player: NodePath, players_x_riding_position: float):
	
	var player_node := get_node(player)
	
	riders.push_back(player_node)
	
	player_node.x_riding_position = players_x_riding_position
	player_node.riding = self

@rpc("any_peer", "call_remote", "reliable", 0)
func _remove_player_as_rider(player: NodePath):
	
	var player_node := get_node(player)
	
	if riders.has(player_node):
		riders.remove_at(riders.find(player_node))
	
	player_node.riding = null

func _physics_process(delta: float) -> void:
	
	if not is_local:
		
		# we're syncing position on a proxy variable so that we can change how
		# position is synced when riding another player (otherwise looks kinda
		# jittery/laggy from the ridden's perspective)
		# 1. when riding, y position is determined for the ridden by the ridden
		# 2. when riding, x position is local to the ridden instead of global
		# not the best explanation but I'll make these comments better later
		if riding:
			global_position.x = x_riding_position + riding.global_position.x
		else:
			global_position.x = x_position
			global_position.y = y_position
		return
	
	if riding:
		x_riding_position = global_position.x - riding.global_position.x
	
	x_position = global_position.x
	y_position = global_position.y

	# assuming we aren't currently being launched by a bouncepad, handle movement
	if launch_time > 0.3:
		
		var move: float
		
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			
			move = Input.get_axis("move_left", "move_right")
			
			if move:
				# accelerate faster on a wall to climb up 2 tile ledges
				velocity.x = lerp(velocity.x, (1000.0 if is_on_wall() else 300.0) * move, 6.0 * delta)
			
			# jump
			if time_since_grounded < 0.2 and Input.is_action_pressed("jump"):
				velocity.y = -500.0
				time_since_grounded = 0.2
		
		if not move:
			velocity.x = lerp(velocity.x, 0.0, 6.0 * delta)
	
	launch_time += delta
	
	# gravity
	velocity.y += 1200.0 * delta

	# before moving, temporarily turn off the collision of all riders so we
	# don't hit them when jumping
	for rider in riders:
		rider.collision_layer = 0

	# move
	var prev_velocity := velocity
	move_and_slide()
	
	# reenable the collision of riders, and place them directly on top of us
	# (networking may have synced their y to put them where is now inside of us,
	# and we don't want them to fall outside the detection of $RiderDetector)
	for rider in riders:
		rider.collision_layer = 1
		rider.global_position.y = global_position.y - 38
	
	# instead of stopping on a collision, redirect velocity along normal
	if is_on_wall():
		velocity = prev_velocity - get_wall_normal() * prev_velocity.dot(get_wall_normal())
	
	if is_on_floor():
		velocity = prev_velocity - get_floor_normal() * prev_velocity.dot(get_floor_normal())
		time_since_grounded = 0.0
	else:
		time_since_grounded += delta
	
	# animation
	if velocity.x < -1:
		$Sprite.flip_h = true
	elif velocity.x > 1:
		$Sprite.flip_h = false
	
	if is_on_floor():
		$AnimationPlayer.current_animation = "idle" if abs(velocity.x) < 4.0 else "run"
		$AnimationPlayer.speed_scale = pow(abs(velocity.x) / 300.0, 0.2)
	else:
		$AnimationPlayer.current_animation = "jump"
