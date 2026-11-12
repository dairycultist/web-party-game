extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	
	print(body)
	
	if body is CharacterBody2D:
		
		body.velocity = -650 * transform.y
