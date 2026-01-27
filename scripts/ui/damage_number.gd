## DamageNumber.gd
## Floating damage number that appears when units take damage.
## Animates upward with gravity effect and fades out.
extends Label

## Upward velocity with slight gravity
var velocity: Vector2 = Vector2(0, -50)

## How long the number stays visible
var lifetime: float = 1.0

func _ready() -> void:
	# Style the damage text
	add_theme_font_size_override("font_size", 24)
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 2)
	
	# Center the text
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Animate fade out and cleanup
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	# Move upward
	position += velocity * delta
	
	# Apply gravity effect (slow down upward movement)
	velocity.y += 80 * delta
