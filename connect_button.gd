extends Button

enum ClientType {
	HOST,
	REMOTE
}

@export var client_type: ClientType

@export var ip_input: LineEdit
@export var port_input: LineEdit
@export var username_input: LineEdit
@export var failure_label: Label

func _ready() -> void:
	button_down.connect(_on_button_down)
	
	# ensure you can't enter invalid characters in the username field
	username_input.text_changed.connect(func (new_text):
		var column := username_input.caret_column
		username_input.text = RegEx.create_from_string("[^A-Za-z0-9_]+").sub(new_text, "", true)
		username_input.set_caret_column(column)
	)

func _on_button_down():
	
	disabled = true
	text = "Attempting to connect..."
	failure_label.text = ""
	
	var ip := ip_input.text.strip_edges() if client_type == ClientType.REMOTE and ip_input.text else "127.0.0.1"
	var port := port_input.text.to_int() if port_input.text else 19132
	var username := username_input.text
	
	if username == "":
		failure_label.text = "Username must not be empty."
	else:
		
		var result := await Network.host_server(username, port)\
			if client_type == ClientType.HOST\
			else await Network.join_server(username, ip, port)
		
		match result:
			Error.ERR_CANT_CREATE:
				failure_label.text = "Network could not be created."
			Error.ERR_CANT_CONNECT:
				failure_label.text = "No response from server."
			Error.ERR_ALREADY_EXISTS:
				failure_label.text = "Server exists but username is taken."
			Error.ERR_UNAVAILABLE:
				failure_label.text = "Server is full (8 players max)."
	
	text = "Connect" if client_type == ClientType.REMOTE else "Start server"
	disabled = false
