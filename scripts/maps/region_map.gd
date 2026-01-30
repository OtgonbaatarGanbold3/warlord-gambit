## RegionMap.gd
## Node-based navigation within a region (like Slay the Spire's map).
## Players progress through Combat, Event, Shop, and Boss nodes.
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var title_label: Label = $TitleLabel
@onready var info_label: Label = $InfoLabel
@onready var back_button: Button = $BackButton
@onready var node_container: HBoxContainer = $NodeContainer

# Store references to node buttons
var node_buttons: Array[Button] = []

# =============================================================================
# NODE CONFIGURATION
# =============================================================================

## Define what type each node is for each region
## Format: Array of node types per region
const REGION_NODES: Dictionary = {
	0: ["COMBAT", "COMBAT", "EVENT", "SHOP", "BOSS"], # Borderlands (5 nodes)
	1: ["COMBAT", "EVENT", "COMBAT", "SHOP", "COMBAT", "EVENT", "BOSS"], # Northern Holds (7 nodes)
	2: ["COMBAT", "COMBAT", "EVENT", "COMBAT", "SHOP", "COMBAT", "EVENT", "BOSS"] # Southern Wastes (8 nodes)
}

## Display names for regions
const REGION_NAMES: Array[String] = ["BORDERLANDS", "NORTHERN HOLDS", "SOUTHERN WASTES"]

## Icons for each node type
const NODE_ICONS: Dictionary = {
	"COMBAT": "⚔️",
	"EVENT": "❓",
	"SHOP": "🛒",
	"BOSS": "💀",
	"ELITE": "👹"
}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[RegionMap] Scene loaded for region %d" % RunManager.current_region)
	
	# Connect back button
	back_button.pressed.connect(_on_back_pressed)
	
	# Get all node buttons from container
	for child in node_container.get_children():
		if child is Button:
			node_buttons.append(child)
	
	# Setup the map for current region
	_setup_region_map()
	_update_ui()


## Sets up the node buttons based on current region
func _setup_region_map() -> void:
	var region = RunManager.current_region
	var nodes = REGION_NODES.get(region, REGION_NODES[0])
	
	print("[RegionMap] Setting up %d nodes for region %d" % [nodes.size(), region])
	
	# First, hide all existing node buttons
	for button in node_buttons:
		button.visible = false
	
	# Then show and configure only the ones we need
	for i in range(nodes.size()):
		if i < node_buttons.size():
			var button = node_buttons[i]
			var node_type = nodes[i]
			
			button.visible = true
			button.text = "%s\n%s" % [NODE_ICONS.get(node_type, "?"), node_type]
			
			# Connect button signal (disconnect first to avoid duplicates)
			if button.pressed.is_connected(_on_node_pressed):
				button.pressed.disconnect(_on_node_pressed)
			button.pressed.connect(_on_node_pressed.bind(i))
		else:
			# Need more buttons than we have - create dynamically (future improvement)
			push_warning("[RegionMap] Not enough node buttons! Need %d, have %d" % [nodes.size(), node_buttons.size()])


## Updates UI elements based on RunManager state
func _update_ui() -> void:
	var region = RunManager.current_region
	var current_node = RunManager.current_node
	var completed = RunManager.completed_nodes
	
	# Update title
	title_label.text = "%s - Region Map" % REGION_NAMES[region]
	
	# Update info
	info_label.text = "Node: %d | Gold: %d | Army: %d units" % [
		current_node + 1,
		RunManager.gold,
		RunManager.army_roster.size()
	]
	
	# Update button states
	var nodes = REGION_NODES.get(region, REGION_NODES[0])
	
	for i in range(min(nodes.size(), node_buttons.size())):
		var button = node_buttons[i]
		var node_type = nodes[i]
		var icon = NODE_ICONS.get(node_type, "?")
		
		if i in completed:
			# Completed node
			button.text = "✅\nDONE"
			button.disabled = true
		elif i == current_node:
			# Current node (can click)
			button.text = "%s\n%s\n▶" % [icon, node_type]
			button.disabled = false
		elif i == current_node + 1 and current_node in completed:
			# Next node (unlocked after completing current)
			button.text = "%s\n%s" % [icon, node_type]
			button.disabled = false
		else:
			# Locked node
			button.text = "%s\n%s\n🔒" % [icon, node_type]
			button.disabled = true

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_back_pressed() -> void:
	print("[RegionMap] Returning to World Map")
	get_tree().change_scene_to_file("res://scenes/maps/world_map.tscn")


func _on_node_pressed(node_index: int) -> void:
	var region = RunManager.current_region
	var nodes = REGION_NODES.get(region, REGION_NODES[0])
	var node_type = nodes[node_index]
	
	print("[RegionMap] Node %d selected: %s" % [node_index, node_type])
	
	# Update RunManager
	RunManager.current_node = node_index
	
	# Handle based on node type
	match node_type:
		"COMBAT", "ELITE":
			_start_combat(node_index, node_type == "ELITE")
		"EVENT":
			_start_event(node_index)
		"SHOP":
			_open_shop()
		"BOSS":
			_start_boss_battle()


func _start_combat(node_index: int, is_elite: bool) -> void:
	print("[RegionMap] Starting %s combat at node %d" % ["ELITE" if is_elite else "NORMAL", node_index])
	
	# Go to deployment screen before battle
	get_tree().change_scene_to_file("res://scenes/deployment/deployment_screen.tscn")

func _start_event(node_index: int) -> void:
	print("[RegionMap] Starting event at node %d" % node_index)
	
	# TEMPORARY: Auto-complete
	RunManager.completed_nodes.append(node_index)
	RunManager.current_node = node_index + 1
	_update_ui()
	
	print("[RegionMap] (Event scene not created yet - auto-completing for testing)")


func _open_shop() -> void:
	print("[RegionMap] Opening shop")
	
	# TEMPORARY: Auto-complete
	var node_index = RunManager.current_node
	RunManager.completed_nodes.append(node_index)
	RunManager.current_node = node_index + 1
	_update_ui()
	
	print("[RegionMap] (Shop scene not created yet - auto-completing for testing)")


func _start_boss_battle() -> void:
	print("[RegionMap] Starting BOSS battle!")
	
	# TEMPORARY: Auto-complete and advance region
	var node_index = RunManager.current_node
	RunManager.completed_nodes.append(node_index)
	RunManager.on_battle_won()
	RunManager.advance_to_next_region()
	
	print("[RegionMap] (Boss defeated! Advancing to next region...)")
	
	# Go back to world map to select next region
	get_tree().change_scene_to_file("res://scenes/maps/world_map.tscn")