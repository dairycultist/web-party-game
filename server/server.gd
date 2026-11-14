extends Node
class_name Server

# wario ware with a little move or die
# FLEE! / STAB!
# ASCEND!
# PAINT!
# STACK!


enum RoundType {
	OutOfRound,
	Test
}

var _round_timer := 3.0
var _round_type: RoundType = RoundType.OutOfRound

func _enter_tree() -> void:
	Network.connect_to_server_signal(
		_on_peer_connected,
		_on_peer_disconnected
	)

func _process(delta: float) -> void:
	
	_round_timer -= delta
	
	if _round_timer < 0.0:
		if _round_type == RoundType.OutOfRound:
			_round_timer = 10.0
			_round_type = RoundType.Test
			trigger_into_round.rpc()
		else:
			_round_timer = 3.0
			_round_type = RoundType.OutOfRound
			trigger_out_of_round.rpc()
	
	$HUD/TimerLabel.text = str(int(ceil(_round_timer)))

func _on_peer_connected(_id: int):
	pass

func _on_peer_disconnected(_id: int):
	pass

@rpc("any_peer", "call_remote", "reliable", 0)
func trigger_out_of_round():
	pass

@rpc("any_peer", "call_remote", "reliable", 0)
func trigger_into_round():
	pass

# need to consume RPCs clients send between each other even if we do nothing with them
@rpc("any_peer", "call_local", "reliable", 0)
func send_message(_msg: String, _is_system_msg: bool):
	pass

@rpc("any_peer", "call_local", "reliable", 0)
func spawn_player(_username: String):
	pass
