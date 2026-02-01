## DeploymentScreen.gd
## Pre-battle screen where players select which units to deploy.
## Max 8 units can be deployed from the army roster.
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var title_label: Label = $TitleLabel
@onready var army_list: ItemList = $MainContainer/ArmyPanel/ArmyList
@onready var wounded_list: ItemList = $MainContainer/ArmyPanel/WoundedList
@onready var squad_list: ItemList = $MainContainer/SquadPanel/SquadList
@onready var squad_count_label: Label = $SquadCountLabel

@onready var back_button: Button = $ButtonContainer/BackButton
@onready var add_button: Button = $ButtonContainer/AddButton
@onready var remove_button: Button = $ButtonContainer/RemoveButton
@onready var auto_deploy_button: Button = $ButtonContainer/AutoDeployButton
@onready var start_battle_button: Button = $ButtonContainer/StartBattleButton

# =============================================================================
# LOCAL STATE
# =============================================================================

## Units currently selected for deployment (local copy until confirmed)
var selected_squad: Array[UnitData] = []

## Available units (not wounded, not in squad)
var available_units: Array[UnitData] = []

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[Deployment] Screen loaded")
	print("[Deployment] is_boss_battle: %s" % str(RunManager.is_boss_battle))
	print("[Deployment] current_region: %d, current_node: %d" % [RunManager.current_region, RunManager.current_node])
	
	# Connect button signals
	back_button.pressed.connect(_on_back_pressed)
	add_button.pressed.connect(_on_add_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	auto_deploy_button.pressed.connect(_on_auto_deploy_pressed)
	start_battle_button.pressed.connect(_on_start_battle_pressed)
	
	# Connect list signals for double-click
	army_list.item_activated.connect(_on_army_item_activated)
	squad_list.item_activated.connect(_on_squad_item_activated)
	
	# Connect list signals for selection change (enables/disables buttons)
	army_list.item_selected.connect(_on_army_list_item_selected)
	squad_list.item_selected.connect(_on_squad_list_item_selected)
	
	# Initialize from RunManager
	_load_from_run_manager()
	_update_ui()

## Loads current state from RunManager
func _load_from_run_manager() -> void:
	# Get available units (not wounded)
	available_units = []
	for unit in RunManager.army_roster:
		if unit not in RunManager.wounded_units:
			available_units.append(unit)
	
	# Start with current active squad or empty
	selected_squad = RunManager.active_squad.duplicate()
	
	# Remove squad members from available list
	for unit in selected_squad:
		if unit in available_units:
			available_units.erase(unit)
	
	print("[Deployment] Available: %d, Squad: %d, Wounded: %d" % [
		available_units.size(),
		selected_squad.size(),
		RunManager.wounded_units.size()
	])


## Updates all UI elements
func _update_ui() -> void:
	_populate_army_list()
	_populate_squad_list()
	_populate_wounded_list()
	_update_squad_count()
	_update_button_states()


## Populates the available army list
func _populate_army_list() -> void:
	army_list.clear()
	
	for unit in available_units:
		var display_text = _get_unit_display_text(unit)
		army_list.add_item(display_text)


## Populates the battle squad list
func _populate_squad_list() -> void:
	squad_list.clear()
	
	# Show 8 slots (filled or empty)
	for i in range(RunManager.MAX_SQUAD_SIZE):
		if i < selected_squad.size():
			var unit = selected_squad[i]
			var display_text = "%d. %s" % [i + 1, _get_unit_display_text(unit)]
			squad_list.add_item(display_text)
		else:
			squad_list.add_item("%d. (empty)" % [i + 1])


## Populates the wounded list
func _populate_wounded_list() -> void:
	wounded_list.clear()
	
	if RunManager.wounded_units.size() == 0:
		wounded_list.add_item("(none)")
	else:
		for unit in RunManager.wounded_units:
			var battles_left = RunManager.wound_recovery.get(unit, 0)
			wounded_list.add_item("%s (recovers in %d battles)" % [unit.unit_name, battles_left])


## Updates the squad count display
func _update_squad_count() -> void:
	squad_count_label.text = "Squad: %d/%d" % [selected_squad.size(), RunManager.MAX_SQUAD_SIZE]
	
	# Color code based on squad size
	if selected_squad.size() == 0:
		squad_count_label.add_theme_color_override("font_color", Color.RED)
	elif selected_squad.size() < RunManager.MAX_SQUAD_SIZE:
		squad_count_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		squad_count_label.add_theme_color_override("font_color", Color.GREEN)


## Updates button enabled/disabled states
func _update_button_states() -> void:
	# Check if anything is selected in army list
	var army_selection = army_list.get_selected_items()
	var army_has_selection = army_selection.size() > 0
	var squad_not_full = selected_squad.size() < RunManager.MAX_SQUAD_SIZE
	
	# Add button: enabled if army has selection AND squad not full
	add_button.disabled = not (army_has_selection and squad_not_full)
	
	# Check if anything is selected in squad list
	var squad_selection = squad_list.get_selected_items()
	var squad_has_selection = squad_selection.size() > 0
	
	# Check if selected squad item is a real unit (not an empty slot)
	var squad_has_valid_unit = false
	if squad_has_selection:
		var selected_index = squad_selection[0]
		squad_has_valid_unit = selected_index < selected_squad.size()
	
	# Remove button: enabled if squad has a valid unit selected
	remove_button.disabled = not squad_has_valid_unit
	
	# Start battle: enabled if at least 1 unit in squad
	start_battle_button.disabled = selected_squad.size() == 0

## Returns display text for a unit
func _get_unit_display_text(unit: UnitData) -> String:
	return "%s [%s] - HP:%d ATK:%d DEF:%d" % [
		unit.unit_name,
		unit.unit_type,
		unit.base_hp,
		unit.base_atk,
		unit.base_def
	]

# =============================================================================
# SQUAD MANAGEMENT
# =============================================================================

## Adds selected unit from army to squad
func _add_unit_to_squad() -> void:
	var selected_items = army_list.get_selected_items()
	if selected_items.size() == 0:
		return
	
	if selected_squad.size() >= RunManager.MAX_SQUAD_SIZE:
		print("[Deployment] Squad is full!")
		return
	
	var index = selected_items[0]
	if index >= available_units.size():
		return
	
	var unit = available_units[index]
	
	# Move from available to squad
	available_units.erase(unit)
	selected_squad.append(unit)
	
	print("[Deployment] Added %s to squad" % unit.unit_name)
	_update_ui()


## Removes selected unit from squad back to army
func _remove_unit_from_squad() -> void:
	var selected_items = squad_list.get_selected_items()
	if selected_items.size() == 0:
		return
	
	var index = selected_items[0]
	if index >= selected_squad.size():
		return # Empty slot selected
	
	var unit = selected_squad[index]
	
	# Move from squad to available
	selected_squad.erase(unit)
	available_units.append(unit)
	
	print("[Deployment] Removed %s from squad" % unit.unit_name)
	_update_ui()


## Auto-fills squad with strongest available units
func _auto_deploy() -> void:
	print("[Deployment] Auto-deploying...")
	
	# Clear current squad (return to available)
	for unit in selected_squad:
		available_units.append(unit)
	selected_squad.clear()
	
	# Sort available by "power" (simple: HP + ATK + DEF)
	available_units.sort_custom(func(a, b):
		var power_a = a.base_hp + a.base_atk + a.base_def
		var power_b = b.base_hp + b.base_atk + b.base_def
		return power_a > power_b
	)
	
	# Take up to MAX_SQUAD_SIZE units
	while selected_squad.size() < RunManager.MAX_SQUAD_SIZE and available_units.size() > 0:
		var unit = available_units[0]
		available_units.erase(unit)
		selected_squad.append(unit)
	
	print("[Deployment] Auto-deployed %d units" % selected_squad.size())
	_update_ui()

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_back_pressed() -> void:
	print("[Deployment] Returning to region map")
	get_tree().change_scene_to_file("res://scenes/maps/region_map.tscn")


func _on_add_pressed() -> void:
	_add_unit_to_squad()


func _on_remove_pressed() -> void:
	_remove_unit_from_squad()


func _on_auto_deploy_pressed() -> void:
	_auto_deploy()


func _on_start_battle_pressed() -> void:
	if selected_squad.size() == 0:
		print("[Deployment] Cannot start battle with no units!")
		return
	
	# Save squad to RunManager
	var typed_squad: Array[UnitData] = []
	for unit in selected_squad:
		typed_squad.append(unit)
	RunManager.set_active_squad(typed_squad)
	
	print("[Deployment] Starting battle with %d units!" % selected_squad.size())
	print("[Deployment] is_boss_battle going into battle: %s" % str(RunManager.is_boss_battle))
	
	# Go to battle scene
	# TODO: Change this to your actual battle scene path
	get_tree().change_scene_to_file("res://scenes/main.tscn")


## Double-click on army list adds to squad
func _on_army_item_activated(index: int) -> void:
	army_list.select(index)
	_add_unit_to_squad()


## Double-click on squad list removes from squad
func _on_squad_item_activated(index: int) -> void:
	squad_list.select(index)
	_remove_unit_from_squad()

## Called when army list selection changes
func _on_army_list_item_selected(_index: int) -> void:
	_update_button_states()


## Called when squad list selection changes  
func _on_squad_list_item_selected(_index: int) -> void:
	_update_button_states()
