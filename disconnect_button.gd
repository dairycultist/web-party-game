extends Button

func _ready() -> void:
	button_down.connect(_on_button_down)

func _on_button_down():
	Network.leave_server()
