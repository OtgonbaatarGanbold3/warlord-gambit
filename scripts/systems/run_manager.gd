## RunManager.gd
## Autoload singleton that manages the state of a roguelike run.
## Tracks army, gold, current region/node, and run progression.
## Persists between scene changes (battle → map → shop → battle).
##
## This is the BRAIN of your roguelike - everything flows through here.
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when gold amount changes
signal gold_changed(new_amount: int)

## Emitted when a unit is added to the army
signal unit_recruited(unit_data: UnitData)

## Emitted when a unit is wounded
signal unit_wounded(unit_data: UnitData)

## Emitted when a unit is healed
signal unit_healed(unit_data: UnitData)

## Emitted when moving to a new region
signal region_changed(region_index: int)

## Emitted when the run ends (victory or defeat)
signal run_ended(victory: bool)

# =============================================================================
# RUN STATE
# =============================================================================

## Is a run currently active?
var run_active: bool = false

## Current region index (0 = Borderlands, 1 = Northern Holds, 2 = Southern Wastes)
var current_region: int = 0

## Current node index within the region
var current_node: int = 0

## Which nodes have been completed in current region
var completed_nodes: Array[int] = []

## Player's gold
var gold: int = 0

## Selected faction for this run
var selected_faction: String = "ROMAN"

## Selected formation for this run
var selected_formation: String = "PHALANX"

# =============================================================================
# ARMY MANAGEMENT
# =============================================================================

## All units in the player's army (UnitData resources)
var army_roster: Array[UnitData] = []

## Units selected for the next battle (max 8)
var active_squad: Array[UnitData] = []

## Units currently wounded and recovering
var wounded_units: Array[UnitData] = []

## How many battles until wounded units recover (unit_data -> battles remaining)
var wound_recovery: Dictionary = {}

## Maximum squad size for deployment
const MAX_SQUAD_SIZE: int = 8

## Starting army size
const STARTING_ARMY_SIZE: int = 5

## Whether the current battle is a boss battle
var is_boss_battle: bool = false

## How many regions are unlocked (starts at 1)
var regions_unlocked: int = 1

# =============================================================================
# INVENTORY
# =============================================================================

## Items not currently equipped to any unit
var inventory: Array[ItemData] = []

# =============================================================================
# RUN STATISTICS
# =============================================================================

## Total battles won this run
var battles_won: int = 0

## Total enemies defeated this run
var enemies_defeated: int = 0

## Total gold earned this run
var total_gold_earned: int = 0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	print("[RunManager] Initialized")


## Starts a new run with the selected faction and formation
## Call this when player clicks "Start Run" from main menu
func start_new_run(faction: String, formation: String) -> void:
	print("[RunManager] Starting new run - Faction: %s, Formation: %s" % [faction, formation])
	
	# Reset all run state
	run_active = true
	current_region = 0
	current_node = 0
	completed_nodes = []
	gold = 100 # Starting gold
	selected_faction = faction
	selected_formation = formation

	is_boss_battle = false
	regions_unlocked = 1
	
	# Reset army
	army_roster = []
	active_squad = []
	wounded_units = []
	wound_recovery = {}
	inventory = []
	
	# Reset statistics
	battles_won = 0
	enemies_defeated = 0
	total_gold_earned = 0
	
	# Create starting army based on faction
	_create_starting_army(faction)
	
	print("[RunManager] Run started with %d units and %d gold" % [army_roster.size(), gold])


## Creates the starting army for the given faction
func _create_starting_army(faction: String) -> void:
	# Path to unit data resources
	var base_path = "res://resources/unit_data/"
	
	# Define starting units per faction
	var starting_units: Array[String] = []
	
	match faction:
		"ROMAN":
			starting_units = [
				"roman_centurion.tres", # Hero
				"roman_legionnaire.tres", # Elite Warrior
				"roman_archer.tres", # Elite Archer
				"roman_pawn.tres", # Pawn 1
				"roman_pawn.tres" # Pawn 2
			]
		"BARBARIAN":
			starting_units = [
				"barbarian_warlord.tres",
				"barbarian_berserker.tres",
				"barbarian_hunter.tres",
				"barbarian_warrior.tres",
				"barbarian_warrior.tres"
			]
		_:
			# Default to Roman if faction not found
			push_warning("[RunManager] Unknown faction: %s, defaulting to ROMAN" % faction)
			_create_starting_army("ROMAN")
			return
	
	# Load each unit and add to roster
	for unit_file in starting_units:
		var unit_path = base_path + unit_file
		var unit_data = load(unit_path) as UnitData
		
		if unit_data:
			army_roster.append(unit_data)
			print("[RunManager] Added starting unit: %s" % unit_data.unit_name)
		else:
			push_error("[RunManager] Failed to load unit: %s" % unit_path)
	
	# Auto-fill active squad with all starting units
	for unit in army_roster:
		if active_squad.size() < MAX_SQUAD_SIZE:
			active_squad.append(unit)

# =============================================================================
# GOLD MANAGEMENT
# =============================================================================

## Adds gold to the player's total
func add_gold(amount: int) -> void:
	gold += amount
	total_gold_earned += amount
	gold_changed.emit(gold)
	print("[RunManager] Gained %d gold. Total: %d" % [amount, gold])


## Spends gold if player has enough. Returns true if successful.
func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		print("[RunManager] Spent %d gold. Remaining: %d" % [amount, gold])
		return true
	else:
		print("[RunManager] Not enough gold! Have: %d, Need: %d" % [gold, amount])
		return false

# =============================================================================
# ARMY MANAGEMENT
# =============================================================================

## Recruits a new unit to the army
func recruit_unit(unit_data: UnitData) -> void:
	army_roster.append(unit_data)
	unit_recruited.emit(unit_data)
	print("[RunManager] Recruited: %s. Army size: %d" % [unit_data.unit_name, army_roster.size()])


## Marks a unit as wounded (called when unit HP reaches 0 in battle)
func wound_unit(unit_data: UnitData, recovery_battles: int = 2) -> void:
	if unit_data in active_squad:
		active_squad.erase(unit_data)
	
	if unit_data not in wounded_units:
		wounded_units.append(unit_data)
		wound_recovery[unit_data] = recovery_battles
		unit_wounded.emit(unit_data)
		print("[RunManager] Unit wounded: %s (recovers in %d battles)" % [unit_data.unit_name, recovery_battles])


## Heals a specific wounded unit (usually via shop)
func heal_unit(unit_data: UnitData) -> void:
	if unit_data in wounded_units:
		wounded_units.erase(unit_data)
		wound_recovery.erase(unit_data)
		unit_healed.emit(unit_data)
		print("[RunManager] Unit healed: %s" % unit_data.unit_name)


## Processes wound recovery after a battle (call after each battle)
func process_wound_recovery() -> void:
	var healed_units: Array[UnitData] = []
	
	for unit_data in wounded_units:
		if wound_recovery.has(unit_data):
			wound_recovery[unit_data] -= 1
			
			if wound_recovery[unit_data] <= 0:
				healed_units.append(unit_data)
				print("[RunManager] %s has recovered!" % unit_data.unit_name)
	
	# Remove healed units from wounded list
	for unit_data in healed_units:
		heal_unit(unit_data)


## Sets the active squad for the next battle
## Returns false if invalid (e.g., too many units, wounded units included)
func set_active_squad(units: Array[UnitData]) -> bool:
	# Validate squad size
	if units.size() > MAX_SQUAD_SIZE:
		push_error("[RunManager] Squad too large! Max: %d" % MAX_SQUAD_SIZE)
		return false
	
	# Validate no wounded units
	for unit in units:
		if unit in wounded_units:
			push_error("[RunManager] Cannot deploy wounded unit: %s" % unit.unit_name)
			return false
		if unit not in army_roster:
			push_error("[RunManager] Unit not in roster: %s" % unit.unit_name)
			return false
	
	active_squad = units.duplicate()
	print("[RunManager] Active squad set: %d units" % active_squad.size())
	return true


## Gets units available for deployment (not wounded)
func get_available_units() -> Array[UnitData]:
	var available: Array[UnitData] = []
	for unit in army_roster:
		if unit not in wounded_units:
			available.append(unit)
	return available

# =============================================================================
# PROGRESSION
# =============================================================================

## Called when a battle is won
func on_battle_won() -> void:
	battles_won += 1
	process_wound_recovery()
	print("[RunManager] Battle won! Total victories: %d" % battles_won)


## Marks the current node as completed and unlocks next
func complete_current_node() -> void:
	if current_node not in completed_nodes:
		completed_nodes.append(current_node)
	print("[RunManager] Completed node %d in region %d" % [current_node, current_region])


## Moves to the next region (called after beating region boss)
func advance_to_next_region() -> void:
	current_region += 1
	current_node = 0
	completed_nodes = []
	region_changed.emit(current_region)
	print("[RunManager] Advanced to region %d" % current_region)
	
	# Check for victory (completed all 3 regions)
	if current_region >= 3:
		end_run(true)


## Ends the current run
func end_run(victory: bool) -> void:
	run_active = false
	run_ended.emit(victory)
	
	if victory:
		print("[RunManager] === RUN COMPLETE - VICTORY! ===")
	else:
		print("[RunManager] === RUN OVER - DEFEAT ===")
	
	print("[RunManager] Stats - Battles: %d, Enemies: %d, Gold: %d" % [
		battles_won, enemies_defeated, total_gold_earned
	])

# =============================================================================
# INVENTORY MANAGEMENT
# =============================================================================

## Adds an item to inventory
func add_item(item_data: ItemData) -> void:
	inventory.append(item_data)
	print("[RunManager] Added item to inventory: %s" % item_data.item_name)


## Removes an item from inventory (when equipped or sold)
func remove_item(item_data: ItemData) -> bool:
	if item_data in inventory:
		inventory.erase(item_data)
		return true
	return false

# =============================================================================
# SAVE/LOAD (for future implementation)
# =============================================================================

## Returns a dictionary of the current run state for saving
func get_save_data() -> Dictionary:
	return {
		"run_active": run_active,
		"current_region": current_region,
		"current_node": current_node,
		"completed_nodes": completed_nodes,
		"gold": gold,
		"selected_faction": selected_faction,
		"selected_formation": selected_formation,
		"battles_won": battles_won,
		"enemies_defeated": enemies_defeated,
		"total_gold_earned": total_gold_earned
		# Note: Unit data paths would need to be stored separately
	}


## Called when a boss is defeated and region is complete
func complete_region(region_index: int) -> void:
	print("[RunManager] Region %d COMPLETE!" % region_index)
	
	# Unlock next region
	if region_index + 1 < 3:
		regions_unlocked = max(regions_unlocked, region_index + 2)
		print("[RunManager] Unlocked region %d" % (region_index + 1))
	
	# Bonus rewards for beating a boss
	var boss_gold_bonus = 100 + (region_index * 50)
	add_gold(boss_gold_bonus)
	print("[RunManager] Boss bonus: +%d gold!" % boss_gold_bonus)
	
	# Heal some wounded units as celebration
	var healed = 0
	var to_heal = wounded_units.duplicate()
	for unit in to_heal:
		if randf() < 0.5: # 50% chance to heal each wounded
			heal_unit(unit)
			healed += 1
	
	if healed > 0:
		print("[RunManager] %d wounded units recovered!" % healed)

## Loads run state from a save dictionary
func load_save_data(data: Dictionary) -> void:
	run_active = data.get("run_active", false)
	current_region = data.get("current_region", 0)
	current_node = data.get("current_node", 0)
	completed_nodes = data.get("completed_nodes", [])
	gold = data.get("gold", 0)
	selected_faction = data.get("selected_faction", "ROMAN")
	selected_formation = data.get("selected_formation", "PHALANX")
	battles_won = data.get("battles_won", 0)
	enemies_defeated = data.get("enemies_defeated", 0)
	total_gold_earned = data.get("total_gold_earned", 0)
	print("[RunManager] Save data loaded")
