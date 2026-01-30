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
	
	# Update region buttons based on progression
	var current_region = RunManager.current_region
	
	# Region 1 - Always unlocked
	region1_button.disabled = false
	_update_region_button(region1_button, 0, current_region)
	
	# Region 2 - Unlocked after completing region 1
	region2_button.disabled = current_region < 1
	_update_region_button(region2_button, 1, current_region)
	
	# Region 3 - Unlocked after completing region 2
	region3_button.disabled = current_region < 2
	_update_region_button(region3_button, 2, current_region)


## Updates a single region button's appearance
func _update_region_button(button: Button, region_index: int, current_region: int) -> void:
	var region_name = REGION_NAMES[region_index]
	var difficulty = REGION_DIFFICULTY[region_index]
	
	if region_index < current_region:
		# Completed region
		button.text = "%s\n(%s)\n✅ CONQUERED" % [region_name, difficulty]
	elif region_index == current_region:
		# Current region (playable)
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
## Enters the selected region and switches to the region map scene
func _enter_region(region_index: int) -> void:
	# Verify player can enter this region
	if region_index > RunManager.current_region:
		print("[WorldMap] Cannot enter locked region!")
		return
	
	# Update RunManager
	RunManager.current_region = region_index
	RunManager.current_node = 0
	RunManager.completed_nodes = []
	
	print("[WorldMap] Entering region %d..." % region_index)
	
	# Switch to Region Map scene
	get_tree().change_scene_to_file("res://scenes/maps/region_map.tscn")
	# Update RunManager
	RunManager.current_region = region_index
	RunManager.current_node = 0
	RunManager.completed_nodes = []
	
	print("[WorldMap] Entering region %d..." % region_index)
	
	# Switch to Region Map scene (we'll create this next!)
	# For now, just print - we'll uncomment this later
	# get_tree().change_scene_to_file("res://scenes/maps/region_map.tscn")
	
	# TEMPORARY: For testing, let's go directly to battle
	print("[WorldMap] (Region Map not yet created - would transition here)")