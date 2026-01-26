# ItemData Resource
# This resource defines equipment items that can be equipped to units to
# enhance their combat statistics. Items are a key part of the roguelike
# progression in Warlord's Gambit.
#
# HOW ITEMS WORK:
# - Each unit can equip items in different slots (Weapon, Armor, Accessory)
# - Item bonuses are added directly to unit's current stats
# - Total stat = base_stat + item_bonuses + formation_bonuses
# - Items are found as loot, purchased, or unlocked between runs
# - Rarity affects the power of stat bonuses and special effects
#
# RARITY GUIDELINES:
# - COMMON: +1-3 to a single stat, no special effect
# - UNCOMMON: +2-5 to stats, may have minor special effect
# - RARE: +4-8 to stats, usually has special effect
# - LEGENDARY: +6-12 to stats, powerful unique special effect
#
# Usage: Create ItemData resources in resources/items/ folder

extends Resource
class_name ItemData

## The display name of this item (e.g., "Iron Sword", "Roman Shield")
@export var item_name: String = ""

## Item rarity - affects drop rates and power level
## COMMON: Basic items, frequently found
## UNCOMMON: Better items, moderate drop rate
## RARE: Powerful items, low drop rate
## LEGENDARY: Unique powerful items, very rare
@export_enum("COMMON", "UNCOMMON", "RARE", "LEGENDARY") var rarity: String = "COMMON"

## Which equipment slot this item occupies
## WEAPON: Offensive items that typically boost ATK
## ARMOR: Defensive items that typically boost DEF and HP
## ACCESSORY: Utility items that can boost any stat or provide special effects
@export_enum("WEAPON", "ARMOR", "ACCESSORY") var slot_type: String = "WEAPON"

## Bonus to maximum HP when equipped
## Typical values: COMMON 0-5, UNCOMMON 5-10, RARE 10-20, LEGENDARY 15-30
@export var hp_bonus: int = 0

## Bonus to attack power when equipped
## Added to unit's current_atk for damage calculation
## Typical values: COMMON 1-2, UNCOMMON 2-4, RARE 4-6, LEGENDARY 6-10
@export var atk_bonus: int = 0

## Bonus to defense when equipped
## Added to unit's current_def to reduce incoming damage
## Typical values: COMMON 1-2, UNCOMMON 2-4, RARE 4-6, LEGENDARY 6-10
@export var def_bonus: int = 0

## Bonus to speed when equipped
## Higher speed means acting earlier in combat turn order
## Typical values: COMMON 0-1, UNCOMMON 1-2, RARE 2-3, LEGENDARY 3-5
@export var speed_bonus: int = 0

## Description of any special ability this item grants
## Examples:
## - "10% chance to deal double damage"
## - "Regenerate 2 HP at start of each turn"
## - "Immune to critical hits"
## - "+3 ATK when HP is below 50%"
## Leave empty if item only provides stat bonuses
@export var special_effect: String = ""

## Flavor text description shown in UI tooltips and inventory
## Describe the item's lore or appearance
@export var description: String = ""

## The icon/sprite displayed in inventory and equipment UI
## Assign a Texture2D resource (PNG, etc.) from assets/sprites folder
@export var icon: Texture2D
