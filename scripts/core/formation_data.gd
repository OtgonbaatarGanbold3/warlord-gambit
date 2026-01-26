# FormationData Resource
# This resource defines formation bonuses that apply to units based on their
# positioning on the battlefield. Formations are a core tactical mechanic in
# Warlord's Gambit that reward strategic unit placement.
#
# HOW FORMATIONS WORK:
# - Units receive bonuses when positioned according to the formation pattern
# - Each faction has preferred formations that match their playstyle
# - Bonuses are applied at the start of combat based on unit positions
# - Breaking formation (moving units out of position) removes the bonuses
#
# EXAMPLE FORMATIONS:
# - PHALANX: Units in a tight horizontal line gain DEF bonus
# - WEDGE: Units in a V-shape gain ATK bonus for piercing enemy lines
# - SCATTERED: Units spread apart gain SPD bonus, harder to hit with AOE
# - SHIELD_WALL: Front row units gain massive DEF, protect back row
# - TESTUDO: All adjacent units share defensive bonuses (Roman specialty)
#
# Usage: Create FormationData resources in resources/formations/ folder

extends Resource
class_name FormationData

## The display name of this formation (e.g., "Roman Phalanx", "Viking Shield Wall")
@export var formation_name: String = ""

## The type/pattern of this formation
## PHALANX: Horizontal line formation - balanced bonuses
## WEDGE: V-shaped offensive formation - ATK focused
## SCATTERED: Spread out formation - SPD focused, anti-AOE
## SHIELD_WALL: Defensive line - high DEF for front units
## TESTUDO: Tight defensive square - shared DEF (Roman specialty)
## BERSERKER_CHARGE: Loose aggressive formation - high ATK, low DEF (Barbarian)
## CRESCENT: Curved flanking formation - bonus to side attacks
@export var formation_type: String = "PHALANX"

## Text description explaining the formation's tactical purpose
## Shown in UI tooltips and formation selection screen
@export var description: String = ""

## Attack bonus granted to units in this formation
## Applied additively to unit's current_atk stat
## Typical values: 0-5 for balanced, 5-10 for offensive formations
@export var atk_bonus: int = 0

## Defense bonus granted to units in this formation
## Applied additively to unit's current_def stat
## Typical values: 0-5 for balanced, 5-15 for defensive formations
@export var def_bonus: int = 0

## Speed bonus granted to units in this formation
## Applied additively to unit's current_speed stat
## Higher speed means acting earlier in combat
## Typical values: 0-3 for most formations, 3-5 for mobile formations
@export var speed_bonus: int = 0

## Description of any special ability this formation grants
## Examples:
## - "Adjacent allies share 50% of DEF bonus"
## - "First attack each turn deals +50% damage"
## - "Units cannot be flanked while in formation"
## - "Counterattack damage increased by 25%"
## Leave empty if formation only provides stat bonuses
@export var special_effect: String = ""
