extends Node
class_name Server

# wario ware with a little move or die
# FLEE! / STAB!
# ASCEND!
# PAINT!
# STACK!

# determines what scene to initialize with, what player modifications to initialize
# with, how long the timer should be, the intro blurb, how to score points at the end, etc

var _round_timer: float
var _in_round: bool
var _possible_rounds: Array[Dictionary] = [
	{
		"blurb": "TEST!",
		"time": 8
	},
	{
		"blurb": "STACK!",
		"time": 3
	},
]

var _curr_round: Dictionary

func _enter_tree() -> void:
	Network.connect_to_server_signal(
		_on_peer_connected,
		_on_peer_disconnected
	)

func _ready() -> void:
	
	_in_round = false
	
	_round_timer = 3.0
	_curr_round = _possible_rounds.pick_random()

func _process(delta: float) -> void:
	
	_round_timer -= delta
	
	if _round_timer < 0.0:
		
		if _in_round:
			# ending/going out of a round
			_round_timer = 3
			_curr_round = _possible_rounds.pick_random()
			# TODO have to RPC each client individually
			_end_round.rpc(null, 0, 0)
		else:
			# starting new round
			_round_timer = _curr_round.get("time")
			$HUD/BlurbLabel.text = _curr_round.get("blurb")
			_start_round.rpc()
		
		_in_round = not _in_round
	
	$HUD/TimerLabel.text = str(int(ceil(_round_timer)))

func _on_peer_connected(_id: int):
	pass

func _on_peer_disconnected(_id: int):
	pass

@rpc("any_peer", "call_remote", "reliable", 0)
func _end_round(_next_scene_to_preload, _player_start_x: float, _player_start_y: float):
	pass

@rpc("any_peer", "call_remote", "reliable", 0)
func _start_round():
	pass

# need to consume RPCs clients send between each other even if we do nothing with them
@rpc("any_peer", "call_local", "reliable", 0)
func send_message(_msg: String, _is_system_msg: bool):
	pass

@rpc("any_peer", "call_local", "reliable", 0)
func spawn_player(_username: String):
	pass
