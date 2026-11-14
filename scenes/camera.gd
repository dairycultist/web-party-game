extends Camera2D

@export var target: Node2D
@export var following: bool = true

func _process(delta: float) -> void:
	
	if target and following:
		zoom = lerp(zoom, Vector2(1.2, 1.2), 3.0 * delta)
		
		global_position = lerp(global_position, target.global_position * Vector2(100.0 / 500, 100.0 / 250), 5.0 * delta)
	else:
		zoom = lerp(zoom, Vector2.ONE, 3.0 * delta)
