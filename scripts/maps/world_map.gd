## WorldMap.gd
## The region selection screen where players choose which area to conquer.
## Displays 3 regions with locked/unlocked states based on progression.
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var region1_button: Button = $RegionContainer/Region1Button
@onready var region2_button: Button = $RegionContainer/Region2Button
@onready var region3_button: Button = $RegionContainer/Region3Button
@onready var gold_label: Label = $GoldLabel
@onready var army_label: Label = $ArmyLabel

# =============================================================================
# REGION DATA
# =============================================================================

## Region names for display
const REGION_NAMES: Array[String] = ["BORDERLANDS", "NORTHERN HOLDS", "SOUTHERN WASTES"]

## Region difficulties
const REGION_DIFFICULTY: Array[String] = ["Easy", "Medium", "Hard"]

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[WorldMap] Scene loaded")
	print("[WorldMap] regions_unlocked: %d, current_region: %d" % [RunManager.regions_unlocked, RunManager.current_region])
	
	# Start a new run if one isn't active
	if not RunManager.run_active:
		print("[WorldMap] Starting new run...")
		RunManager.start_new_run("ROMAN", "PHALANX")
	
	# Connect button signals
	region1_button.pressed.connect(_on_region1_pressed)
	region2_button.pressed.connect(_on_region2_pressed)
	region3_button.pressed.connect(_on_region3_pressed)
	
	# Update UI based on RunManager state
	_update_ui()


## Updates all UI elements based on current run state
func _update_ui() -> void:
	# Update gold and army count
	gold_label.text = "Gold: %d" % RunManager.gold
	army_label.text = "Army: %d units" % RunManager.army_roster.size()
	
	# Use regions_unlocked to determine which buttons are enabled
	var unlocked = RunManager.regions_unlocked
	
	print("[WorldMap] ===== _update_ui =====")
	print("[WorldMap] regions_unlocked: %d" % unlocked)
	print("[WorldMap] current_region: %d" % RunManager.current_region)
	print("[WorldMap] is_boss_battle: %s" % str(RunManager.is_boss_battle))
	
	# Region 1 - Always unlocked
	region1_button.disabled = false
	_update_region_button(region1_button, 0, unlocked)
	print("[WorldMap] Region 1 button disabled: %s" % str(region1_button.disabled))
	
	# Region 2 - Unlocked when regions_unlocked >= 2
	region2_button.disabled = unlocked < 2
	_update_region_button(region2_button, 1, unlocked)
	print("[WorldMap] Region 2 button disabled: %s (needs unlocked >= 2, got %d)" % [str(region2_button.disabled), unlocked])
	
	# Region 3 - Unlocked when regions_unlocked >= 3
	region3_button.disabled = unlocked < 3
	_update_region_button(region3_button, 2, unlocked)
	print("[WorldMap] Region 3 button disabled: %s (needs unlocked >= 3, got %d)" % [str(region3_button.disabled), unlocked])


## Updates a single region button's appearance
func _update_region_button(button: Button, region_index: int, regions_unlocked: int) -> void:
	var region_name = REGION_NAMES[region_index]
	var difficulty = REGION_DIFFICULTY[region_index]
	
	# Region is completed if its index is less than (regions_unlocked - 1)
	# e.g., if regions_unlocked = 2, then region 0 is complete
	if region_index < regions_unlocked - 1:
		# Completed region
		button.text = "%s\n(%s)\n✅ CONQUERED" % [region_name, difficulty]
	elif region_index < regions_unlocked:
		# Unlocked but not completed (current region to play)
		button.text = "%s\n(%s)\n▶ ENTER" % [region_name, difficulty]
	else:
		# Locked region
		button.text = "%s\n(%s)\n🔒 LOCKED" % [region_name, difficulty]


# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_region1_pressed() -> void:
	print("[WorldMap] Region 1 (Borderlands) selected")
	_enter_region(0)


func _on_region2_pressed() -> void:
	print("[WorldMap] Region 2 (Northern Holds) selected")
	_enter_region(1)


func _on_region3_pressed() -> void:
	print("[WorldMap] Region 3 (Southern Wastes) selected")
	_enter_region(2)


## Enters the selected region and switches to the region map scene
func _enter_region(region_index: int) -> void:
	# Verify player can enter this region
	if region_index >= RunManager.regions_unlocked:
		print("[WorldMap] Cannot enter locked region %d! (unlocked: %d)" % [region_index, RunManager.regions_unlocked])
		return
	
	# Update RunManager
	RunManager.current_region = region_index
	RunManager.current_node = 0
	RunManager.completed_nodes = []
	
	print("[WorldMap] Entering region %d..." % region_index)
	
	# Switch to Region Map scene
	get_tree().change_scene_to_file("res://scenes/maps/region_map.tscn")
