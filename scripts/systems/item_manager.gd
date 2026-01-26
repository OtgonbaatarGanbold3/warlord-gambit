## ItemManager.gd
## Autoload singleton that manages item inventory, equipment, and drops.
## Handles loading items from resources, equipping/unequipping on units,
## applying stat bonuses, and generating random loot drops.
##
## RARITY DROP RATES:
## - Common: 60%
## - Uncommon: 25%
## - Rare: 12%
## - Legendary: 3%
##
## SETUP:
## 1. Project → Project Settings → Autoload tab
## 2. Add this script with Node Name: "ItemManager"
## 3. Click "Add" to register as singleton
extends Node

# =============================================================================
# PROPERTIES
# =============================================================================

## Master list of all available items loaded from resources
var all_items: Array = []

## Items sorted by rarity for weighted random drops
var item_pool_common: Array = []
var item_pool_uncommon: Array = []
var item_pool_rare: Array = []
var item_pool_legendary: Array = []

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when an item is equipped on a unit
## @param unit: The unit that equipped the item
## @param item: The ItemData that was equipped
signal item_equipped(unit, item)

## Emitted when an item is unequipped from a unit
## @param unit: The unit that unequipped the item
## @param item: The ItemData that was removed
signal item_unequipped(unit, item)

## Emitted when an item is generated as a drop (from enemy death, chest, etc.)
## @param item: The ItemData that dropped
signal item_dropped(item)

# =============================================================================
# INITIALIZATION
# =============================================================================

## Called when the node enters the scene tree
## Loads all item resources from the items directory
func _ready() -> void:
	print("[ItemManager] Initializing...")
	load_all_items()
	print("[ItemManager] Initialization complete!")


## Loads all ItemData resources from the resources/items/ directory
## Automatically sorts items into rarity pools for drop generation
func load_all_items() -> void:
	var items_path: String = "res://resources/items/"
	
	# Attempt to open the items directory
	var dir: DirAccess = DirAccess.open(items_path)
	
	if not dir:
		push_error("[ItemManager] Could not open items directory: " + items_path)
		return
	
	# Clear existing pools in case of reload
	all_items.clear()
	item_pool_common.clear()
	item_pool_uncommon.clear()
	item_pool_rare.clear()
	item_pool_legendary.clear()
	
	# Iterate through all files in the directory
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		# Only process .tres resource files
		if file_name.ends_with(".tres"):
			var full_path: String = items_path + file_name
			var item = load(full_path)
			
			# Verify it's an ItemData resource
			if item is ItemData:
				all_items.append(item)
				
				# Sort into appropriate rarity pool
				match item.rarity:
					"COMMON":
						item_pool_common.append(item)
					"UNCOMMON":
						item_pool_uncommon.append(item)
					"RARE":
						item_pool_rare.append(item)
					"LEGENDARY":
						item_pool_legendary.append(item)
					_:
						push_warning("[ItemManager] Unknown rarity '%s' for item: %s" % [item.rarity, item.item_name])
						item_pool_common.append(item) # Default to common
			else:
				push_warning("[ItemManager] File is not ItemData: " + file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Print loading summary
	print("[ItemManager] Loaded %d items:" % all_items.size())
	print("[ItemManager]   Common: %d" % item_pool_common.size())
	print("[ItemManager]   Uncommon: %d" % item_pool_uncommon.size())
	print("[ItemManager]   Rare: %d" % item_pool_rare.size())
	print("[ItemManager]   Legendary: %d" % item_pool_legendary.size())

# =============================================================================
# EQUIPMENT MANAGEMENT
# =============================================================================

## Equips an item on a unit, handling slot conflicts automatically
## If the unit already has an item in that slot, it will be unequipped first
## @param unit: The unit to equip the item on
## @param item: The ItemData to equip
## @return: true if equip was successful
func equip_item(unit, item: ItemData) -> bool:
	if not unit or not item:
		push_error("[ItemManager] Cannot equip: unit or item is null")
		return false
	
	# Ensure unit has equipped_items array
	if not "equipped_items" in unit:
		push_error("[ItemManager] Unit does not have equipped_items property")
		return false
	
	# Check if unit already has an item in this slot
	var existing_item: ItemData = get_equipped_item_in_slot(unit, item.slot_type)
	if existing_item:
		# Automatically unequip the existing item
		unequip_item(unit, existing_item)
	
	# Add item to unit's equipped items
	unit.equipped_items.append(item)
	
	# Apply the item's stat bonuses
	apply_item_bonuses(unit, item)
	
	# Emit signal for UI updates, achievements, etc.
	item_equipped.emit(unit, item)
	
	print("[ItemManager] Equipped '%s' on unit at %s" % [item.item_name, unit.grid_position])
	return true


## Unequips an item from a unit, removing its stat bonuses
## @param unit: The unit to unequip from
## @param item: The ItemData to remove
## @return: true if unequip was successful
func unequip_item(unit, item: ItemData) -> bool:
	if not unit or not item:
		push_error("[ItemManager] Cannot unequip: unit or item is null")
		return false
	
	# Check if item is actually equipped
	if item not in unit.equipped_items:
		push_warning("[ItemManager] Item '%s' is not equipped on this unit" % item.item_name)
		return false
	
	# Remove from equipped items array
	unit.equipped_items.erase(item)
	
	# Remove the item's stat bonuses
	remove_item_bonuses(unit, item)
	
	# Emit signal for UI updates
	item_unequipped.emit(unit, item)
	
	print("[ItemManager] Unequipped '%s'" % item.item_name)
	return true


## Finds the item equipped in a specific slot on a unit
## @param unit: The unit to check
## @param slot_type: The slot to look for (e.g., "WEAPON", "ARMOR", "ACCESSORY")
## @return: The ItemData in that slot, or null if empty
func get_equipped_item_in_slot(unit, slot_type: String) -> ItemData:
	if not unit or not "equipped_items" in unit:
		return null
	
	for item in unit.equipped_items:
		if item is ItemData and item.slot_type == slot_type:
			return item
	
	return null

# =============================================================================
# STAT BONUS APPLICATION
# =============================================================================

## Applies an item's stat bonuses to a unit
## Called automatically when equipping an item
## @param unit: The unit receiving the bonuses
## @param item: The ItemData providing the bonuses
func apply_item_bonuses(unit, item: ItemData) -> void:
	if not unit or not item:
		return
	
	# Add HP bonus (both max and current)
	unit.max_hp += item.hp_bonus
	unit.current_hp += item.hp_bonus
	
	# Add combat stat bonuses
	unit.current_atk += item.atk_bonus
	unit.current_def += item.def_bonus
	unit.current_speed += item.speed_bonus
	
	# Update unit's visual display (health bar, etc.)
	if unit.has_method("update_visuals"):
		unit.update_visuals()
	
	print("[ItemManager] Applied bonuses: HP+%d, ATK+%d, DEF+%d, SPD+%d" % [
		item.hp_bonus, item.atk_bonus, item.def_bonus, item.speed_bonus
	])


## Removes an item's stat bonuses from a unit
## Called automatically when unequipping an item
## @param unit: The unit losing the bonuses
## @param item: The ItemData being removed
func remove_item_bonuses(unit, item: ItemData) -> void:
	if not unit or not item:
		return
	
	# Remove HP bonus
	unit.max_hp -= item.hp_bonus
	# Ensure current HP doesn't exceed new max
	unit.current_hp = mini(unit.current_hp, unit.max_hp)
	
	# Remove combat stat bonuses
	unit.current_atk -= item.atk_bonus
	unit.current_def -= item.def_bonus
	unit.current_speed -= item.speed_bonus
	
	# Update unit's visual display
	if unit.has_method("update_visuals"):
		unit.update_visuals()
	
	print("[ItemManager] Removed bonuses: HP-%d, ATK-%d, DEF-%d, SPD-%d" % [
		item.hp_bonus, item.atk_bonus, item.def_bonus, item.speed_bonus
	])

# =============================================================================
# ITEM DROPS & GENERATION
# =============================================================================

## Generates a random item drop based on rarity weights
## Drop rates: 60% Common, 25% Uncommon, 12% Rare, 3% Legendary
## @return: A random ItemData, or null if no items available
func generate_random_item_drop() -> ItemData:
	# Roll for rarity (0.0 to 1.0)
	var roll: float = randf()
	
	# Determine which pool to draw from based on roll
	var pool: Array = []
	var rarity_name: String = ""
	
	if roll < 0.60:
		# 60% chance for Common (0.00 - 0.59)
		pool = item_pool_common
		rarity_name = "Common"
	elif roll < 0.85:
		# 25% chance for Uncommon (0.60 - 0.84)
		pool = item_pool_uncommon
		rarity_name = "Uncommon"
	elif roll < 0.97:
		# 12% chance for Rare (0.85 - 0.96)
		pool = item_pool_rare
		rarity_name = "Rare"
	else:
		# 3% chance for Legendary (0.97 - 1.00)
		pool = item_pool_legendary
		rarity_name = "Legendary"
	
	# Handle empty pools by falling back to common
	if pool.size() == 0:
		pool = item_pool_common
		rarity_name = "Common (fallback)"
	
	# Still no items? Return null
	if pool.size() == 0:
		push_warning("[ItemManager] No items available for drop generation")
		return null
	
	# Pick a random item from the selected pool
	var item: ItemData = pool[randi() % pool.size()]
	
	# Emit signal for drop effects, notifications, etc.
	item_dropped.emit(item)
	
	print("[ItemManager] Generated %s drop: %s" % [rarity_name, item.item_name])
	return item


## Calculates a unit's total stats including all equipped items
## Useful for UI display and combat calculations
## @param unit: The unit to calculate stats for
## @return: Dictionary with total hp, atk, def, speed
func get_total_stats(unit) -> Dictionary:
	if not unit:
		return {"hp": 0, "atk": 0, "def": 0, "speed": 0}
	
	# Start with unit's current stats
	var total: Dictionary = {
		"hp": unit.max_hp,
		"atk": unit.current_atk,
		"def": unit.current_def,
		"speed": unit.current_speed
	}
	
	# Note: Item bonuses are already applied to unit stats when equipped
	# This function is for display purposes if you want to show breakdown
	# The stats returned here are the unit's current totals
	
	return total


## Gets a breakdown of stats from equipped items only
## Useful for showing item contribution in UI
## @param unit: The unit to check
## @return: Dictionary with item-only bonuses
func get_item_stat_bonuses(unit) -> Dictionary:
	var bonuses: Dictionary = {
		"hp": 0,
		"atk": 0,
		"def": 0,
		"speed": 0
	}
	
	if not unit or not "equipped_items" in unit:
		return bonuses
	
	for item in unit.equipped_items:
		if item is ItemData:
			bonuses.hp += item.hp_bonus
			bonuses.atk += item.atk_bonus
			bonuses.def += item.def_bonus
			bonuses.speed += item.speed_bonus
	
	return bonuses


## Gets an item by name from the loaded items
## @param item_name: The name to search for
## @return: ItemData with matching name, or null
func get_item_by_name(item_name: String) -> ItemData:
	for item in all_items:
		if item.item_name == item_name:
			return item
	return null


## Gets all items of a specific slot type
## @param slot_type: The slot type to filter by (e.g., "WEAPON")
## @return: Array of ItemData matching the slot type
func get_items_by_slot(slot_type: String) -> Array:
	var result: Array = []
	for item in all_items:
		if item.slot_type == slot_type:
			result.append(item)
	return result
