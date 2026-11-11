extends Node

# This script provides helpers for hosting, joining, and leaving a server.

# To get information about the network connection, use the "multiplayer"
# property local to a given node (since one Network can have both a client
# and server with different network connection properties).
# For example, "multiplayer.is_server()" and "multiplayer.get_unique_id()"

# To get information about the network game logic, use "Network.server_node"
# and "Network.client_node".
# For example, "Network.client_node.local_username"

var _server := ENetMultiplayerPeer.new()
var _client := ENetMultiplayerPeer.new()

var server_api: MultiplayerAPI
var client_api: MultiplayerAPI

var server_node: Server
var client_node: Client

func host_server(username: String, port: int) -> Error:

	# create a local server
	var result := _server.create_server(port, 8)
	
	if result != Error.OK:
		return result
	
	# create a client to connect to the local server
	result = _client.create_client("127.0.0.1", port)
	
	if result != Error.OK:
		_server.close()
		return result
	
	# load the scene, waiting for both its children to enter the tree (but not
	# yet call _ready) so we can set up their path's multiplayer API
	server_api = SceneMultiplayer.new()
	server_api.multiplayer_peer = _server
	
	client_api = SceneMultiplayer.new()
	client_api.multiplayer_peer = _client
	
	get_tree().change_scene_to_file("res://scenes/networked.tscn")
	await get_tree().root.child_entered_tree
	await get_tree().current_scene.child_entered_tree
	await get_tree().current_scene.child_entered_tree
	
	server_node = get_tree().current_scene.get_node("Server")
	server_node.get_tree().set_multiplayer(server_api, server_node.get_path())
	
	client_node = get_tree().current_scene.get_node("Client")
	client_node.get_tree().set_multiplayer(client_api, client_node.get_path())
	client_node.local_username = username
	
	return Error.OK

func join_server(username: String, address: String, port: int) -> Error:
	
	# create a client to connect to the remote server
	var result := _client.create_client(address, port)
	
	if result != Error.OK:
		return result
	
	# load the scene, waiting for both its children to enter the tree (but not
	# yet call _ready) so we can set up the client's path's multiplayer API and
	# destroy the server node
	client_api = SceneMultiplayer.new()
	client_api.multiplayer_peer = _client
	
	get_tree().change_scene_to_file("res://scenes/networked.tscn")
	await get_tree().root.child_entered_tree
	await get_tree().current_scene.child_entered_tree
	await get_tree().current_scene.child_entered_tree
	
	get_tree().current_scene.get_node("Server").queue_free()
	
	client_node = get_tree().current_scene.get_node("Client")
	client_node.get_tree().set_multiplayer(client_api, client_node.get_path())
	client_node.local_username = username
	
	return Error.OK

func leave_server(reason: String = "") -> void:
	
	server_node = null
	client_node = null
	
	server_api = null
	client_api = null
	
	get_tree().change_scene_to_file("res://scenes/title.tscn")
	await get_tree().scene_changed
	
	_client.close()
	_server.close()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().current_scene.get_node("DisconnectReasonLabel").text = reason

func connect_to_server_signal(on_peer_connected: Callable, on_peer_disconnected: Callable):
	
	server_api.peer_connected.connect(on_peer_connected)
	server_api.peer_disconnected.connect(on_peer_disconnected)

func connect_to_client_signal(on_peer_connected: Callable, on_peer_disconnected: Callable,
	on_connected_to_server: Callable, on_connection_failed: Callable, on_server_disconnected: Callable):
	
	client_api.peer_connected.connect(on_peer_connected)
	client_api.peer_disconnected.connect(on_peer_disconnected)
	client_api.connected_to_server.connect(on_connected_to_server)
	client_api.connection_failed.connect(on_connection_failed)
	client_api.server_disconnected.connect(on_server_disconnected)
