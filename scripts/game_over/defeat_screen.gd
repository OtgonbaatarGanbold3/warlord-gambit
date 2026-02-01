## DefeatScreen.gd
## Shown when the player loses all units during a run.
## Displays run statistics and options to retry or quit.
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var stats_label: Label = $StatsLabel
@onready var retry_button: Button = $ButtonContainer/RetryButton
@onready var main_menu_button: Button = $ButtonContainer/MainMenuButton

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[DefeatScreen] Run ended in defeat...")
	
	# Connect buttons
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Display run statistics
	_update_stats()


func _update_stats() -> void:
	stats_label.text = "Battles Won: %d | Enemies Defeated: %d | Gold Earned: %d" % [
		RunManager.battles_won,
		RunManager.enemies_defeated,
		RunManager.total_gold_earned
	]

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_retry_pressed() -> void:
	print("[DefeatScreen] Starting new run...")
	
	# Start a fresh run
	RunManager.start_new_run("ROMAN", "PHALANX")
	
	# Go to world map
	get_tree().change_scene_to_file("res://scenes/maps/world_map.tscn")


func _on_main_menu_pressed() -> void:
	print("[DefeatScreen] Returning to main menu...")
	
	# For now, just go to world map (we can add a real main menu later)
	RunManager.start_new_run("ROMAN", "PHALANX")
	get_tree().change_scene_to_file("res://scenes/maps/world_map.tscn")