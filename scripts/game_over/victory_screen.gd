## VictoryScreen.gd
## Shown when the player conquers all 3 regions.
## Displays final run statistics and celebration!
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var stats_label: Label = $StatsLabel
@onready var army_label: Label = $ArmyLabel
@onready var play_again_button: Button = $PlayAgainButton

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[VictoryScreen] 🏆 GAME COMPLETE! 🏆")
	
	# Connect button
	play_again_button.pressed.connect(_on_play_again_pressed)
	
	# Display final statistics
	_update_stats()
	
	# End the run as a victory
	RunManager.end_run(true)


func _update_stats() -> void:
	# Show run statistics
	stats_label.text = "Battles Won: %d | Enemies Defeated: %d | Gold Earned: %d" % [
		RunManager.battles_won,
		RunManager.enemies_defeated,
		RunManager.total_gold_earned
	]
	
	# Show surviving army
	var survivors = RunManager.army_roster.size()
	army_label.text = "Army Survived: %d units" % survivors

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_play_again_pressed() -> void:
	print("[VictoryScreen] Starting new run...")
	
	# Start a fresh run
	RunManager.start_new_run("ROMAN", "PHALANX")
	
	# Go to world map
	get_tree().change_scene_to_file("res://scenes/maps/world_map.tscn")