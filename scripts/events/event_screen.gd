## EventScreen.gd
## Random event encounters with multiple choice outcomes.
## Adds variety and decision-making to each run.
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var event_name_label: Label = $EventNameLabel
@onready var description_label: Label = $ContentContainer/DescriptionPanel/DescriptionMargin/DescriptionLabel
@onready var choices_container: VBoxContainer = $ContentContainer/ChoicesContainer
@onready var choice_a_button: Button = $ContentContainer/ChoicesContainer/ChoiceAButton
@onready var choice_b_button: Button = $ContentContainer/ChoicesContainer/ChoiceBButton
@onready var choice_c_button: Button = $ContentContainer/ChoicesContainer/ChoiceCButton
@onready var outcome_panel: PanelContainer = $ContentContainer/OutcomePanel
@onready var outcome_label: Label = $ContentContainer/OutcomePanel/OutcomeContent/OutcomeLabel
@onready var continue_button: Button = $ContentContainer/OutcomePanel/OutcomeContent/ContinueButton

# =============================================================================
# EVENT DATA
# =============================================================================

## Current event being displayed
var current_event: Dictionary = {}

## All possible events
const EVENTS: Array[Dictionary] = [
	{
		"name": "The Deserter",
		"description": "A wounded enemy soldier stumbles into your camp, begging for mercy. He offers to join your army in exchange for his life. He looks weak but desperate.",
		"choices": [
			{
				"text": "[A] Accept him into your army\n→ Gain a random unit",
				"outcome": "The soldier pledges his loyalty. He may not be the strongest, but every sword helps.",
				"effect": "gain_unit"
			},
			{
				"text": "[B] Demand payment for his freedom\n→ Gain 75 gold",
				"outcome": "The soldier empties his pockets, handing over everything he has before fleeing.",
				"effect": "gain_gold",
				"amount": 75
			},
			{
				"text": "[C] Turn him away\n→ Nothing happens",
				"outcome": "You send him away. He disappears into the wilderness, fate unknown.",
				"effect": "nothing"
			}
		]
	},
	{
		"name": "Ancient Shrine",
		"description": "You discover an ancient shrine hidden in the forest. Strange energy emanates from within. A faded inscription promises power to those who make an offering.",
		"choices": [
			{
				"text": "[A] Make an offering (50 gold)\n→ Receive a blessing or curse",
				"outcome": "The shrine glows! Your soldiers feel invigorated. +1 ATK to all units for next battle!",
				"effect": "blessing",
				"cost": 50
			},
			{
				"text": "[B] Loot the shrine\n→ Gain gold but risk consequences",
				"outcome": "You find 100 gold hidden in the shrine... but one soldier cuts himself on a trap. A unit is wounded!",
				"effect": "loot_shrine"
			},
			{
				"text": "[C] Leave it alone\n→ Continue safely",
				"outcome": "Some things are better left undisturbed. You move on.",
				"effect": "nothing"
			}
		]
	},
	{
		"name": "Merchant Caravan",
		"description": "A traveling merchant caravan crosses your path. The lead merchant eyes your army nervously but offers to trade. His wares look valuable.",
		"choices": [
			{
				"text": "[A] Trade fairly\n→ Buy an item at discount",
				"outcome": "The merchant appreciates honest soldiers. You purchase a fine item at a fair price!",
				"effect": "gain_item"
			},
			{
				"text": "[B] Demand a 'protection fee'\n→ Gain 100 gold",
				"outcome": "The merchant reluctantly hands over gold. 'Soldiers these days...' he mutters.",
				"effect": "gain_gold",
				"amount": 100
			},
			{
				"text": "[C] Let them pass\n→ +1 unit morale (nothing for now)",
				"outcome": "Your soldiers respect your honor. The merchant waves gratefully as he departs.",
				"effect": "nothing"
			}
		]
	},
	{
		"name": "Wounded Warrior",
		"description": "You find a badly wounded warrior from a defeated army. Despite his injuries, he's clearly a skilled veteran. He'll die without help.",
		"choices": [
			{
				"text": "[A] Use medical supplies (30 gold)\n→ Gain an elite unit",
				"outcome": "Your healers save his life. Grateful, the veteran warrior joins your cause!",
				"effect": "gain_elite",
				"cost": 30
			},
			{
				"text": "[B] Take his equipment\n→ Gain a random item",
				"outcome": "You salvage his gear. It's good quality equipment that will serve you well.",
				"effect": "gain_item"
			},
			{
				"text": "[C] Leave him\n→ Continue on",
				"outcome": "You have no resources to spare. War is cruel.",
				"effect": "nothing"
			}
		]
	},
	{
		"name": "The Gambler",
		"description": "A mysterious gambler appears at your camp, offering a game of chance. 'Double or nothing,' he grins, shuffling worn cards. 'What do you say, commander?'",
		"choices": [
			{
				"text": "[A] Gamble 50 gold\n→ 50% chance to double, 50% to lose",
				"outcome": "", # Set dynamically
				"effect": "gamble",
				"amount": 50
			},
			{
				"text": "[B] Gamble 100 gold\n→ 50% chance to double, 50% to lose",
				"outcome": "",
				"effect": "gamble",
				"amount": 100
			},
			{
				"text": "[C] Refuse to play\n→ Keep your gold",
				"outcome": "The gambler shrugs and vanishes into the night. Probably for the best.",
				"effect": "nothing"
			}
		]
	},
	{
		"name": "Ambush!",
		"description": "Scouts report enemy soldiers ahead! They haven't seen you yet. You could attack with surprise, try to sneak past, or take a longer safe route.",
		"choices": [
			{
				"text": "[A] Ambush them!\n→ Gain gold and items from victory",
				"outcome": "Your surprise attack succeeds! The enemies fall quickly, and you claim their supplies.",
				"effect": "ambush_win"
			},
			{
				"text": "[B] Sneak past\n→ 70% success, 30% spotted (lose gold)",
				"outcome": "", # Set dynamically
				"effect": "sneak"
			},
			{
				"text": "[C] Take the long route\n→ Safe but costs 25 gold in supplies",
				"outcome": "The detour is long but safe. You use extra supplies for the journey.",
				"effect": "spend_gold",
				"amount": 25
			}
		]
	}
]

## Unit pool for event rewards
const EVENT_UNIT_POOL: Array[String] = [
	"res://resources/unit_data/roman_pawn.tres",
	"res://resources/unit_data/barbarian_pawn.tres",
]

const EVENT_ELITE_POOL: Array[String] = [
	"res://resources/unit_data/roman_legionnaire.tres",
	"res://resources/unit_data/barbarian_berserker.tres",
]

const EVENT_ITEM_POOL: Array[String] = [
	"res://resources/items/item_iron_sword.tres",
	"res://resources/items/item_steel_shield.tres",
	"res://resources/items/item_health_amulet.tres",
]

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[Event] Event screen loaded!")
	
	# Connect buttons
	choice_a_button.pressed.connect(_on_choice_a)
	choice_b_button.pressed.connect(_on_choice_b)
	choice_c_button.pressed.connect(_on_choice_c)
	continue_button.pressed.connect(_on_continue)
	
	# Hide outcome panel initially
	outcome_panel.visible = false
	choices_container.visible = true
	
	# Pick random event
	_select_random_event()
	
	# Update UI
	_update_ui()


func _select_random_event() -> void:
	current_event = EVENTS[randi() % EVENTS.size()]
	print("[Event] Selected event: %s" % current_event["name"])


func _update_ui() -> void:
	event_name_label.text = '"%s"' % current_event["name"]
	description_label.text = current_event["description"]
	
	var choices = current_event["choices"]
	
	# Update choice buttons
	if choices.size() >= 1:
		choice_a_button.text = choices[0]["text"]
		choice_a_button.visible = true
		# Disable if can't afford
		if choices[0].has("cost") and RunManager.gold < choices[0]["cost"]:
			choice_a_button.disabled = true
			choice_a_button.text += " (Not enough gold!)"
	else:
		choice_a_button.visible = false
	
	if choices.size() >= 2:
		choice_b_button.text = choices[1]["text"]
		choice_b_button.visible = true
		if choices[1].has("cost") and RunManager.gold < choices[1]["cost"]:
			choice_b_button.disabled = true
			choice_b_button.text += " (Not enough gold!)"
	else:
		choice_b_button.visible = false
	
	if choices.size() >= 3:
		choice_c_button.text = choices[2]["text"]
		choice_c_button.visible = true
		if choices[2].has("cost") and RunManager.gold < choices[2]["cost"]:
			choice_c_button.disabled = true
			choice_c_button.text += " (Not enough gold!)"
	else:
		choice_c_button.visible = false

# =============================================================================
# CHOICE HANDLERS
# =============================================================================

func _on_choice_a() -> void:
	_process_choice(0)


func _on_choice_b() -> void:
	_process_choice(1)


func _on_choice_c() -> void:
	_process_choice(2)


func _process_choice(choice_index: int) -> void:
	var choices = current_event["choices"]
	if choice_index >= choices.size():
		return
	
	var choice = choices[choice_index]
	var effect = choice["effect"]
	var outcome_text = choice["outcome"]
	
	print("[Event] Player chose: %s" % effect)
	
	# Process effect and possibly modify outcome text
	match effect:
		"gain_unit":
			var unit_path = EVENT_UNIT_POOL[randi() % EVENT_UNIT_POOL.size()]
			var unit = load(unit_path) as UnitData
			if unit:
				RunManager.recruit_unit(unit)
				outcome_text += "\n\n✅ Gained: %s" % unit.unit_name
		
		"gain_elite":
			if choice.has("cost"):
				RunManager.spend_gold(choice["cost"])
			var unit_path = EVENT_ELITE_POOL[randi() % EVENT_ELITE_POOL.size()]
			var unit = load(unit_path) as UnitData
			if unit:
				RunManager.recruit_unit(unit)
				outcome_text += "\n\n✅ Gained elite: %s" % unit.unit_name
		
		"gain_item":
			var item_path = EVENT_ITEM_POOL[randi() % EVENT_ITEM_POOL.size()]
			var item = load(item_path) as ItemData
			if item:
				RunManager.add_item(item)
				outcome_text += "\n\n✅ Gained: %s" % item.item_name
		
		"gain_gold":
			var amount = choice.get("amount", 50)
			RunManager.add_gold(amount)
			outcome_text += "\n\n✅ Gained: %d gold" % amount
		
		"spend_gold":
			var amount = choice.get("amount", 25)
			RunManager.spend_gold(amount)
			outcome_text += "\n\n💸 Spent: %d gold" % amount
		
		"blessing":
			if choice.has("cost"):
				RunManager.spend_gold(choice["cost"])
			# For now just give gold as placeholder for buff system
			RunManager.add_gold(25)
			outcome_text += "\n\n✨ (Blessing effect - bonus 25 gold for now)"
		
		"loot_shrine":
			RunManager.add_gold(100)
			# Wound a random unit if any available
			var available = RunManager.get_available_units()
			if available.size() > 0:
				var victim = available[randi() % available.size()]
				RunManager.wound_unit(victim, 2)
				outcome_text += "\n\n✅ Gained: 100 gold\n❌ Wounded: %s" % victim.unit_name
			else:
				outcome_text += "\n\n✅ Gained: 100 gold"
		
		"gamble":
			var amount = choice.get("amount", 50)
			if RunManager.gold >= amount:
				RunManager.spend_gold(amount)
				if randf() < 0.5:
					# Win!
					var winnings = amount * 2
					RunManager.add_gold(winnings)
					outcome_text = "Lady luck smiles upon you! The gambler pays up.\n\n✅ Won: %d gold!" % winnings
				else:
					# Lose!
					outcome_text = "The cards betray you. The gambler grins and pockets your gold.\n\n❌ Lost: %d gold" % amount
			else:
				outcome_text = "You don't have enough gold to gamble!"
		
		"sneak":
			if randf() < 0.7:
				# Success
				outcome_text = "Your army slips past unnoticed. The enemies never knew you were there."
			else:
				# Spotted! Lose gold
				var lost = 50
				RunManager.spend_gold(min(lost, RunManager.gold))
				outcome_text = "You're spotted! In the chaos of fleeing, supplies are lost.\n\n❌ Lost: %d gold" % lost
		
		"ambush_win":
			RunManager.add_gold(80)
			var item_path = EVENT_ITEM_POOL[randi() % EVENT_ITEM_POOL.size()]
			var item = load(item_path) as ItemData
			if item:
				RunManager.add_item(item)
				outcome_text += "\n\n✅ Gained: 80 gold + %s" % item.item_name
			else:
				outcome_text += "\n\n✅ Gained: 80 gold"
		
		"nothing":
			pass # No effect
	
	# Show outcome
	_show_outcome(outcome_text)


func _show_outcome(text: String) -> void:
	# Hide choices, show outcome
	choices_container.visible = false
	outcome_panel.visible = true
	outcome_label.text = text


func _on_continue() -> void:
	print("[Event] Event complete, returning to region map")
	
	# Mark event node as complete
	RunManager.complete_current_node()
	RunManager.current_node += 1
	
	# Return to region map
	get_tree().change_scene_to_file("res://scenes/maps/region_map.tscn")
