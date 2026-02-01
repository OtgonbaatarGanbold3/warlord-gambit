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
	
	# Update region buttons based on regions_unlocked (not current_region)
	var unlocked = RunManager.regions_unlocked
	
	print("[WorldMap] Regions unlocked: %d, Current region: %d" % [unlocked, RunManager.current_region])
	
	# Region 1 - Always unlocked
	region1_button.disabled = false
	_update_region_button(region1_button, 0, unlocked)
	
	# Region 2 - Unlocked after completing region 1
	region2_button.disabled = unlocked < 2
	_update_region_button(region2_button, 1, unlocked)
	
	# Region 3 - Unlocked after completing region 2
	region3_button.disabled = unlocked < 3
	_update_region_button(region3_button, 2, unlocked)


## Updates a single region button's appearance
func _update_region_button(button: Button, region_index: int, regions_unlocked: int) -> void:
	var region_name = REGION_NAMES[region_index]
	var difficulty = REGION_DIFFICULTY[region_index]
	
	if region_index < regions_unlocked - 1 or (region_index < RunManager.current_region):
		# Completed region
		button.text = "%s\n(%s)\n✅ CONQUERED" % [region_name, difficulty]
	elif region_index < regions_unlocked:
		# Unlocked region (playable)
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
		print("[WorldMap] Cannot enter locked region!")
		return
	
	# Update RunManager
	RunManager.current_region = region_index
	RunManager.current_node = 0
	RunManager.completed_nodes = []
	
	print("[WorldMap] Entering region %d..." % region_index)
	
	# Switch to Region Map scene
	get_tree().change_scene_to_file("res://scenes/maps/region_map.tscn")