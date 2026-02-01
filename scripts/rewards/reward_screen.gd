## RewardScreen.gd
## Post-battle reward selection screen.
## Player chooses 1 of 3 rewards: Unit, Item, or Gold.
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var victory_label: Label = $VictoryLabel
@onready var stats_label: Label = $StatsLabel

# Unit card
@onready var unit_name_label: Label = $RewardContainer/UnitCard/UnitCardContent/UnitNameLabel
@onready var unit_stats_label: Label = $RewardContainer/UnitCard/UnitCardContent/UnitStatsLabel
@onready var unit_select_button: Button = $RewardContainer/UnitCard/UnitCardContent/UnitSelectButton

# Item card
@onready var item_name_label: Label = $RewardContainer/ItemCard/ItemCardContent/ItemNameLabel
@onready var item_stats_label: Label = $RewardContainer/ItemCard/ItemCardContent/ItemStatsLabel
@onready var item_select_button: Button = $RewardContainer/ItemCard/ItemCardContent/ItemSelectButton

# Gold card
@onready var gold_amount_label: Label = $RewardContainer/GoldCard/GoldCardContent/GoldAmountLabel
@onready var gold_select_button: Button = $RewardContainer/GoldCard/GoldCardContent/GoldSelectButton

# =============================================================================
# REWARD DATA
# =============================================================================

## The unit reward for this battle
var reward_unit: UnitData = null

## The item reward for this battle
var reward_item: ItemData = null

## The gold reward amount
var reward_gold: int = 0

## Enemies defeated (for display)
var enemies_defeated: int = 0

# =============================================================================
# REWARD POOLS
# =============================================================================

const UNIT_REWARD_POOL: Array[String] = [
	"res://resources/unit_data/roman_pawn.tres",
	"res://resources/unit_data/roman_legionnaire.tres",
	"res://resources/unit_data/roman_archer.tres",
	"res://resources/unit_data/barbarian_pawn.tres",
	"res://resources/unit_data/barbarian_berserker.tres",
	"res://resources/unit_data/barbarian_hunter.tres",
]

## Available item rewards (paths to .tres files)
const ITEM_REWARD_POOL: Array[String] = [
	"res://resources/items/item_iron_sword.tres",
	"res://resources/items/item_steel_shield.tres",
	"res://resources/items/item_health_amulet.tres",
	"res://resources/items/item_boots_speed.tres",
	"res://resources/items/item_flame_sword.tres",
	"res://resources/items/item_dragon_armor.tres",
]
# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[RewardScreen] Victory screen loaded!")
	
	# Connect buttons
	unit_select_button.pressed.connect(_on_unit_selected)
	item_select_button.pressed.connect(_on_item_selected)
	gold_select_button.pressed.connect(_on_gold_selected)
	
	# Generate random rewards
	_generate_rewards()
	
	# Update UI
	_update_ui()


## Generates random rewards based on current region
func _generate_rewards() -> void:
	var region = RunManager.current_region
	
	# Gold scales with region
	var base_gold = 80 + (region * 40)
	reward_gold = base_gold + randi_range(-20, 30)
	
	# Random unit from pool
	var unit_path = UNIT_REWARD_POOL[randi() % UNIT_REWARD_POOL.size()]
	reward_unit = load(unit_path) as UnitData
	
	# Random item from pool
	var item_path = ITEM_REWARD_POOL[randi() % ITEM_REWARD_POOL.size()]
	reward_item = load(item_path) as ItemData
	
	# If resources don't exist, create placeholder data
	if reward_unit == null:
		push_warning("[RewardScreen] Could not load unit reward, using placeholder")
		reward_unit = _create_placeholder_unit()
	
	if reward_item == null:
		push_warning("[RewardScreen] Could not load item reward, using placeholder")
		reward_item = _create_placeholder_item()
	
	# Simulated enemies defeated (in real game, pass this from battle)
	enemies_defeated = randi_range(3, 8)
	
	print("[RewardScreen] Rewards generated - Unit: %s, Item: %s, Gold: %d" % [
		reward_unit.unit_name if reward_unit else "None",
		reward_item.item_name if reward_item else "None",
		reward_gold
	])


## Creates a placeholder unit if resources don't exist
func _create_placeholder_unit() -> UnitData:
	var unit = UnitData.new()
	unit.unit_name = "Recruit"
	unit.unit_type = "PAWN"
	unit.faction = "ROMAN"
	unit.base_hp = 30
	unit.base_atk = 10
	unit.base_def = 5
	return unit


## Creates a placeholder item if resources don't exist
func _create_placeholder_item() -> ItemData:
	var item = ItemData.new()
	item.item_name = "Basic Sword"
	item.slot_type = "WEAPON"
	item.rarity = "COMMON"
	item.atk_bonus = 3
	return item


## Updates all UI elements
func _update_ui() -> void:
	# Update unit card
	if reward_unit:
		unit_name_label.text = "%s\n[%s]" % [reward_unit.unit_name, reward_unit.unit_type]
		unit_stats_label.text = "HP:%d ATK:%d DEF:%d" % [
			reward_unit.base_hp,
			reward_unit.base_atk,
			reward_unit.base_def
		]
	else:
		unit_name_label.text = "No Unit"
		unit_stats_label.text = ""
	
	# Update item card
	if reward_item:
		item_name_label.text = "%s\n[%s]" % [reward_item.item_name, reward_item.rarity]
		var stats_parts: Array[String] = []
		if reward_item.hp_bonus > 0:
			stats_parts.append("+%d HP" % reward_item.hp_bonus)
		if reward_item.atk_bonus > 0:
			stats_parts.append("+%d ATK" % reward_item.atk_bonus)
		if reward_item.def_bonus > 0:
			stats_parts.append("+%d DEF" % reward_item.def_bonus)
		if reward_item.speed_bonus > 0:
			stats_parts.append("+%d SPD" % reward_item.speed_bonus)
		item_stats_label.text = "\n".join(stats_parts) if stats_parts.size() > 0 else "No bonus"
	else:
		item_name_label.text = "No Item"
		item_stats_label.text = ""
	
	# Update gold card
	gold_amount_label.text = "%d Gold" % reward_gold
	
	# Update stats
	stats_label.text = "Enemies Defeated: %d | Bonus Gold: +%d" % [
		enemies_defeated,
		enemies_defeated * 10
	]

# =============================================================================
# REWARD SELECTION
# =============================================================================

func _on_unit_selected() -> void:
	print("[RewardScreen] Player chose UNIT reward: %s" % reward_unit.unit_name)
	
	# Add unit to army
	RunManager.recruit_unit(reward_unit)
	
	# Small gold bonus for defeating enemies
	RunManager.add_gold(enemies_defeated * 10)
	
	_finish_reward()


func _on_item_selected() -> void:
	print("[RewardScreen] Player chose ITEM reward: %s" % reward_item.item_name)
	
	# Add item to inventory
	RunManager.add_item(reward_item)
	
	# Small gold bonus
	RunManager.add_gold(enemies_defeated * 10)
	
	_finish_reward()


func _on_gold_selected() -> void:
	print("[RewardScreen] Player chose GOLD reward: %d" % reward_gold)
	
	# Add gold (reward + enemy bonus)
	RunManager.add_gold(reward_gold + enemies_defeated * 10)
	
	_finish_reward()


## Called after any reward is selected
func _finish_reward() -> void:
	# Mark current node as complete
	RunManager.complete_current_node()
	
	# Move to next node
	RunManager.current_node += 1
	
	# Process wound recovery
	RunManager.on_battle_won()
	
	print("[RewardScreen] Reward collected!")
	print("[RewardScreen] Army size: %d, Gold: %d" % [
		RunManager.army_roster.size(),
		RunManager.gold
	])
	print("[RewardScreen] Current region: %d, Current node: %d, Regions unlocked: %d" % [
		RunManager.current_region,
		RunManager.current_node,
		RunManager.regions_unlocked
	])
	
	# Check if we just beat the final boss (all regions complete)
	if RunManager.current_region >= 2 and RunManager.regions_unlocked >= 3:
		# Check if we've passed the last node of region 3
		if RunManager.current_node >= 8: # Region 3 has 8 nodes (0-7)
			print("[RewardScreen] Game complete! Going to victory screen...")
			get_tree().change_scene_to_file("res://scenes/game_over/victory_screen.tscn")
			return
	
	# Check if we just beat a boss (current node is past the last node of region)
	var region_node_counts = {
		0: 5, # Borderlands has 5 nodes (indices 0-4)
		1: 7, # Northern Holds has 7 nodes (indices 0-6)
		2: 8 # Southern Wastes has 8 nodes (indices 0-7)
	}
	var max_nodes = region_node_counts.get(RunManager.current_region, 5)
	
	if RunManager.current_node >= max_nodes:
		print("[RewardScreen] Region %d complete! Going to world map..." % RunManager.current_region)
		# Advance to next region
		RunManager.current_region += 1
		RunManager.current_node = 0
		RunManager.completed_nodes = []
		get_tree().change_scene_to_file("res://scenes/maps/world_map.tscn")
	else:
		# Return to region map
		get_tree().change_scene_to_file("res://scenes/maps/region_map.tscn")