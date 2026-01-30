## ShopScreen.gd
## Shop where players can buy units, items, and heal wounded units.
## Prices scale slightly with region difficulty.
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var gold_label: Label = $GoldLabel
@onready var units_list: ItemList = $MainContainer/LeftPanel/UnitsList
@onready var items_list: ItemList = $MainContainer/RightPanel/ItemsList
@onready var wounded_list: ItemList = $MainContainer/RightPanel/WoundedList
@onready var heal_all_button: Button = $MainContainer/LeftPanel/HealAllButton

@onready var buy_unit_button: Button = $ButtonContainer/BuyUnitButton
@onready var buy_item_button: Button = $ButtonContainer/BuyItemButton
@onready var heal_unit_button: Button = $ButtonContainer/HealUnitButton
@onready var leave_button: Button = $ButtonContainer/LeaveButton

# =============================================================================
# SHOP INVENTORY
# =============================================================================

## Units available for purchase this visit
var shop_units: Array[Dictionary] = [] # [{data: UnitData, price: int}, ...]

## Items available for purchase this visit
var shop_items: Array[Dictionary] = [] # [{data: ItemData, price: int}, ...]

## Cost to heal all wounded units
var heal_all_cost: int = 100

## Cost to heal a single unit
var heal_single_cost: int = 50

# =============================================================================
# UNIT/ITEM POOLS WITH PRICES
# =============================================================================

const UNIT_SHOP_POOL: Array[Dictionary] = [
	{"path": "res://resources/unit_data/roman_pawn.tres", "base_price": 80},
	{"path": "res://resources/unit_data/roman_legionnaire.tres", "base_price": 150},
	{"path": "res://resources/unit_data/roman_archer.tres", "base_price": 130},
	{"path": "res://resources/unit_data/barbarian_pawn.tres", "base_price": 80},
	{"path": "res://resources/unit_data/barbarian_berserker.tres", "base_price": 160},
	{"path": "res://resources/unit_data/barbarian_hunter.tres", "base_price": 140},
]

const ITEM_SHOP_POOL: Array[Dictionary] = [
	{"path": "res://resources/items/item_iron_sword.tres", "base_price": 60},
	{"path": "res://resources/items/item_steel_shield.tres", "base_price": 70},
	{"path": "res://resources/items/item_health_amulet.tres", "base_price": 90},
	{"path": "res://resources/items/item_boots_speed.tres", "base_price": 80},
	{"path": "res://resources/items/item_flame_sword.tres", "base_price": 150},
	{"path": "res://resources/items/item_dragon_armor.tres", "base_price": 200},
]

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[Shop] Shop opened!")
	
	# Connect buttons
	buy_unit_button.pressed.connect(_on_buy_unit_pressed)
	buy_item_button.pressed.connect(_on_buy_item_pressed)
	heal_unit_button.pressed.connect(_on_heal_unit_pressed)
	heal_all_button.pressed.connect(_on_heal_all_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	
	# Connect list selection signals
	units_list.item_selected.connect(_on_unit_selected)
	items_list.item_selected.connect(_on_item_selected)
	wounded_list.item_selected.connect(_on_wounded_selected)
	
	# Generate shop inventory
	_generate_shop_inventory()
	
	# Update UI
	_update_ui()


## Generates random shop inventory based on current region
func _generate_shop_inventory() -> void:
	var region = RunManager.current_region
	var price_multiplier = 1.0 + (region * 0.2) # Prices increase per region
	
	# Clear previous inventory
	shop_units.clear()
	shop_items.clear()
	
	# Pick 3 random units
	var available_units = UNIT_SHOP_POOL.duplicate()
	available_units.shuffle()
	
	for i in range(min(3, available_units.size())):
		var unit_info = available_units[i]
		var unit_data = load(unit_info["path"]) as UnitData
		
		if unit_data:
			var price = int(unit_info["base_price"] * price_multiplier)
			shop_units.append({"data": unit_data, "price": price})
			print("[Shop] Stocking unit: %s for %dg" % [unit_data.unit_name, price])
	
	# Pick 3 random items
	var available_items = ITEM_SHOP_POOL.duplicate()
	available_items.shuffle()
	
	for i in range(min(3, available_items.size())):
		var item_info = available_items[i]
		var item_data = load(item_info["path"]) as ItemData
		
		if item_data:
			var price = int(item_info["base_price"] * price_multiplier)
			shop_items.append({"data": item_data, "price": price})
			print("[Shop] Stocking item: %s for %dg" % [item_data.item_name, price])
	
	# Calculate heal costs
	heal_single_cost = int(50 * price_multiplier)
	heal_all_cost = heal_single_cost * max(1, RunManager.wounded_units.size())


## Updates all UI elements
func _update_ui() -> void:
	_update_gold_display()
	_populate_units_list()
	_populate_items_list()
	_populate_wounded_list()
	_update_button_states()
	_update_heal_all_button()


func _update_gold_display() -> void:
	gold_label.text = "Gold: %d" % RunManager.gold


func _populate_units_list() -> void:
	units_list.clear()
	
	for unit_entry in shop_units:
		var unit: UnitData = unit_entry["data"]
		var price: int = unit_entry["price"]
		var display = "%s [%s] - %dg\nHP:%d ATK:%d DEF:%d" % [
			unit.unit_name,
			unit.unit_type,
			price,
			unit.base_hp,
			unit.base_atk,
			unit.base_def
		]
		units_list.add_item(display)


func _populate_items_list() -> void:
	items_list.clear()
	
	for item_entry in shop_items:
		var item: ItemData = item_entry["data"]
		var price: int = item_entry["price"]
		
		var stats_parts: Array[String] = []
		if item.hp_bonus > 0:
			stats_parts.append("+%d HP" % item.hp_bonus)
		if item.atk_bonus > 0:
			stats_parts.append("+%d ATK" % item.atk_bonus)
		if item.def_bonus > 0:
			stats_parts.append("+%d DEF" % item.def_bonus)
		if item.speed_bonus > 0:
			stats_parts.append("+%d SPD" % item.speed_bonus)
		
		var stats_text = ", ".join(stats_parts) if stats_parts.size() > 0 else "No bonus"
		
		var display = "%s [%s] - %dg\n%s" % [
			item.item_name,
			item.rarity,
			price,
			stats_text
		]
		items_list.add_item(display)


func _populate_wounded_list() -> void:
	wounded_list.clear()
	
	if RunManager.wounded_units.size() == 0:
		wounded_list.add_item("(No wounded units)")
	else:
		for unit in RunManager.wounded_units:
			var battles_left = RunManager.wound_recovery.get(unit, 0)
			var display = "%s - %dg to heal\n(%d battles to auto-recover)" % [
				unit.unit_name,
				heal_single_cost,
				battles_left
			]
			wounded_list.add_item(display)


func _update_heal_all_button() -> void:
	var wounded_count = RunManager.wounded_units.size()
	heal_all_cost = heal_single_cost * max(1, wounded_count)
	
	if wounded_count == 0:
		heal_all_button.text = "No Wounded Units"
		heal_all_button.disabled = true
	else:
		heal_all_button.text = "Heal All (%d) - %dg" % [wounded_count, heal_all_cost]
		heal_all_button.disabled = RunManager.gold < heal_all_cost


func _update_button_states() -> void:
	# Buy unit button
	var unit_selected = units_list.get_selected_items().size() > 0
	var can_afford_unit = false
	if unit_selected:
		var index = units_list.get_selected_items()[0]
		if index < shop_units.size():
			can_afford_unit = RunManager.gold >= shop_units[index]["price"]
	buy_unit_button.disabled = not (unit_selected and can_afford_unit)
	
	# Buy item button
	var item_selected = items_list.get_selected_items().size() > 0
	var can_afford_item = false
	if item_selected:
		var index = items_list.get_selected_items()[0]
		if index < shop_items.size():
			can_afford_item = RunManager.gold >= shop_items[index]["price"]
	buy_item_button.disabled = not (item_selected and can_afford_item)
	
	# Heal unit button
	var wounded_selected = wounded_list.get_selected_items().size() > 0
	var has_wounded = RunManager.wounded_units.size() > 0
	var can_afford_heal = RunManager.gold >= heal_single_cost
	heal_unit_button.disabled = not (wounded_selected and has_wounded and can_afford_heal)

# =============================================================================
# SELECTION HANDLERS
# =============================================================================

func _on_unit_selected(index: int) -> void:
	_update_button_states()


func _on_item_selected(index: int) -> void:
	_update_button_states()


func _on_wounded_selected(index: int) -> void:
	_update_button_states()

# =============================================================================
# PURCHASE HANDLERS
# =============================================================================

func _on_buy_unit_pressed() -> void:
	var selected = units_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var index = selected[0]
	if index >= shop_units.size():
		return
	
	var unit_entry = shop_units[index]
	var unit: UnitData = unit_entry["data"]
	var price: int = unit_entry["price"]
	
	if RunManager.spend_gold(price):
		# Add unit to army
		RunManager.recruit_unit(unit)
		
		# Remove from shop
		shop_units.remove_at(index)
		
		print("[Shop] Purchased unit: %s for %dg" % [unit.unit_name, price])
		
		_update_ui()
	else:
		print("[Shop] Cannot afford unit!")


func _on_buy_item_pressed() -> void:
	var selected = items_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var index = selected[0]
	if index >= shop_items.size():
		return
	
	var item_entry = shop_items[index]
	var item: ItemData = item_entry["data"]
	var price: int = item_entry["price"]
	
	if RunManager.spend_gold(price):
		# Add item to inventory
		RunManager.add_item(item)
		
		# Remove from shop
		shop_items.remove_at(index)
		
		print("[Shop] Purchased item: %s for %dg" % [item.item_name, price])
		
		_update_ui()
	else:
		print("[Shop] Cannot afford item!")


func _on_heal_unit_pressed() -> void:
	var selected = wounded_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var index = selected[0]
	if index >= RunManager.wounded_units.size():
		return
	
	var unit = RunManager.wounded_units[index]
	
	if RunManager.spend_gold(heal_single_cost):
		RunManager.heal_unit(unit)
		print("[Shop] Healed unit: %s for %dg" % [unit.unit_name, heal_single_cost])
		_update_ui()
	else:
		print("[Shop] Cannot afford healing!")


func _on_heal_all_pressed() -> void:
	if RunManager.wounded_units.size() == 0:
		return
	
	if RunManager.spend_gold(heal_all_cost):
		# Heal all wounded units
		var healed_count = RunManager.wounded_units.size()
		
		# Create copy since we're modifying array
		var to_heal = RunManager.wounded_units.duplicate()
		for unit in to_heal:
			RunManager.heal_unit(unit)
		
		print("[Shop] Healed all %d wounded units for %dg" % [healed_count, heal_all_cost])
		_update_ui()
	else:
		print("[Shop] Cannot afford healing all!")


func _on_leave_pressed() -> void:
	print("[Shop] Leaving shop...")
	
	# Mark shop node as complete
	RunManager.complete_current_node()
	RunManager.current_node += 1
	
	# Return to region map
	get_tree().change_scene_to_file("res://scenes/maps/region_map.tscn")