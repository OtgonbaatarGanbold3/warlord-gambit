## TerrainData.gd
## Resource class defining terrain types for tactical gameplay.
## Each terrain type affects movement, combat, and visibility.
##
## TERRAIN EXAMPLES:
## - Plains: Default terrain, no bonuses (cost: 1, DEF: 0)
## - Forest: Dense cover (+3 DEF, provides cover, cost: 2)
## - Mountain: High ground (+2 DEF, +1 ATK, +1 range, cost: 3)
## - Water: Impassable for most units (blocks_movement: true)
## - Lava: Dangerous terrain (damage_per_turn: 10, cost: 2)
##
## USAGE:
## 1. Create new TerrainData resource in Inspector
## 2. Configure properties for the terrain type
## 3. Save as .tres file in resources/terrain/
## 4. Reference in Board or TileMap system
extends Resource
class_name TerrainData

# =============================================================================
# IDENTIFICATION
# =============================================================================

## Display name for this terrain type (e.g., "Dense Forest", "Shallow Water")
@export var terrain_name: String = ""

## Category of terrain - determines base behavior and visuals
## PLAINS: Open ground, default terrain
## FOREST: Wooded area with cover and movement penalty
## MOUNTAIN: Elevated terrain with defensive and range bonuses
## WATER: Lakes, rivers - typically blocks movement
## LAVA: Hazardous terrain that damages units each turn
@export_enum("PLAINS", "FOREST", "MOUNTAIN", "WATER", "LAVA") var terrain_type: String = "PLAINS"

## Flavor text describing the terrain (shown in UI tooltips)
@export_multiline var description: String = ""

# =============================================================================
# MOVEMENT
# =============================================================================

## Movement points required to enter this tile
## Default is 1. Higher values slow units down.
## Examples:
## - Plains: 1 (normal movement)
## - Forest: 2 (difficult terrain)
## - Mountain: 3 (very slow)
## - Swamp: 2-3 (muddy, slows movement)
@export var movement_cost: int = 1

## If true, units cannot enter this tile at all
## Used for deep water, walls, cliffs, etc.
## Note: Some unit types (flying, aquatic) may override this
@export var blocks_movement: bool = false

# =============================================================================
# COMBAT BONUSES
# =============================================================================

## Defense bonus applied to units standing on this terrain
## Added to unit's DEF stat when defending
## Examples:
## - Forest: +3 DEF (trees provide protection)
## - Mountain: +2 DEF (high ground advantage)
## - Plains: +0 DEF (no cover)
@export var defense_bonus: int = 0

## Attack bonus applied when attacking FROM this terrain
## Added to unit's ATK stat when initiating combat
## Examples:
## - Mountain: +1 ATK (high ground strike advantage)
## - Plains: +0 ATK (no bonus)
@export var attack_bonus: int = 0

## Extra attack range for ranged units on this terrain
## Added to unit's attack_range when calculating valid targets
## Examples:
## - Mountain: +1 range (elevated vantage point)
## - Tower: +2 range (extreme height advantage)
## - Plains: +0 range (no bonus)
@export var range_bonus: int = 0

# =============================================================================
# SPECIAL EFFECTS
# =============================================================================

## Damage dealt to units at the start of each turn while on this terrain
## Applied during turn start phase, before unit can act
## Examples:
## - Lava: 10 damage per turn (deadly hazard)
## - Poison Swamp: 5 damage per turn (toxic fumes)
## - Plains: 0 damage (safe terrain)
@export var damage_per_turn: int = 0

## If true, units on this terrain are hidden from ranged attacks
## Enemy ranged units cannot target units with cover unless adjacent
## Examples:
## - Forest: true (trees block line of sight)
## - Ruins: true (walls provide concealment)
## - Plains: false (fully visible)
@export var provides_cover: bool = false

# =============================================================================
# VISUALS
# =============================================================================

## Color tint applied to tiles of this terrain type
## Used for visual distinction on the game board
## Examples:
## - Plains: Color(0.6, 0.8, 0.4) - light green
## - Forest: Color(0.2, 0.5, 0.2) - dark green
## - Mountain: Color(0.5, 0.5, 0.5) - gray
## - Water: Color(0.2, 0.4, 0.8) - blue
## - Lava: Color(1.0, 0.3, 0.1) - orange-red
@export var color: Color = Color.WHITE
