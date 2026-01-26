# UnitData Resource
# This resource defines all the base statistics and properties for a unit
# in Warlord's Gambit. Create instances of this resource in the Godot editor
# to define different unit types (Heroes, Elites, Pawns) for each faction.
#
# Usage: Right-click in FileSystem -> New Resource -> UnitData

extends Resource
class_name UnitData

## The display name of this unit (e.g., "Roman Legionary", "Barbarian Berserker")
@export var unit_name: String = ""

## Unit classification that determines movement patterns and combat role
## HERO: Powerful leader unit (1 per army), moves in all 8 directions
## ELITE_WARRIOR: Melee specialist with extended movement range
## ELITE_ARCHER: Ranged unit with high attack range but lower defense
## PAWN: Basic infantry, moves forward only, forms the bulk of armies
@export var unit_type: String = "PAWN"

## The faction this unit belongs to
## ROMAN, BARBARIAN, SAMURAI, UNDEAD, DESERT, VIKING
@export var faction: String = "ROMAN"

## Base health points - determines how much damage the unit can take
## Typical values: Pawn 20-30, Elite 40-60, Hero 80-100
@export var base_hp: int = 30

## Base attack power - used in damage calculation (damage = ATK - DEF)
## Higher values deal more damage to enemies
@export var base_atk: int = 10

## Base defense - reduces incoming damage
## Damage taken = max(1, attacker_ATK - this_DEF)
@export var base_def: int = 5

## Base speed - determines turn order in combat
## Higher speed units act first
@export var base_speed: int = 5

## How many tiles this unit can move per turn
## Pawn: 1, Elite: 2, Hero: 1-2 depending on faction
@export var movement_range: int = 1

## How far this unit can attack (in tiles)
## Melee units: 1, Archers: 2-3, Some heroes may have special ranges
@export var attack_range: int = 1

## The visual sprite/texture for this unit on the game board
## Assign a Texture2D resource (PNG, etc.) from the assets/sprites folder
@export var sprite_texture: Texture2D

## Short description of the unit for UI tooltips
@export var unit_description: String = ""

## Special abilities or passive effects this unit has
## Use multiple lines to list different abilities
## Example: "Shield Wall: +2 DEF when adjacent to allied Pawn\nFormation Bonus: +1 ATK in Phalanx"
@export_multiline var abilities: String = ""
