extends Area2D

@export var bounce_speed := 650

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	
	print(body)
	
	if body is CharacterBody2D:
		
		body.velocity = -bounce_speed * transform.y
		body.launch_time = 0.0
		body.global_position = global_position - transform.y * 32.0
