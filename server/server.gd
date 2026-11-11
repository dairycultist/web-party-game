extends Node
class_name Server

func _enter_tree() -> void:
	Network.connect_to_server_signal(
		_on_peer_connected,
		_on_peer_disconnected
	)

func _on_peer_connected(_id: int):
	pass

func _on_peer_disconnected(_id: int):
	pass

# need to consume RPCs clients send between each other even if we do nothing with them
@rpc("any_peer", "call_local", "reliable", 0)
func send_message(_msg: String, _is_system_msg: bool):
	pass

@rpc("any_peer", "call_local", "reliable", 0)
func spawn_player(_username: String):
	pass
