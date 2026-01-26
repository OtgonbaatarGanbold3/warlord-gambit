## GameUI.gd
## Manages the game's HUD and UI elements including turn display,
## unit information panel, and player controls.
extends CanvasLayer
class_name GameUI

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when the player presses the end turn button
signal end_turn_pressed

# =============================================================================
# NODE REFERENCES
# =============================================================================

## Label displaying the current turn number
@onready var turn_label: Label = $HUD/TurnLabel

## Label displaying the current phase (player/enemy turn)
@onready var phase_label: Label = $HUD/PhaseLabel

## Button to end the player's turn
@onready var end_turn_button: Button = $HUD/EndTurnButton

## Panel containing unit information
@onready var unit_info_panel: Panel = $HUD/UnitInfoPanel

## Label displaying the selected unit's name
@onready var unit_name_label: Label = $HUD/UnitInfoPanel/UnitNameLabel

## Label displaying the selected unit's type and faction
@onready var unit_type_label: Label = $HUD/UnitInfoPanel/UnitTypeLabel

## Label displaying the selected unit's stats (HP, ATK, DEF, SPD)
@onready var unit_stats_label: Label = $HUD/UnitInfoPanel/UnitStatsLabel

## Label displaying the selected unit's current status (moved, attacked, ready)
@onready var unit_status_label: Label = $HUD/UnitInfoPanel/UnitStatusLabel

# =============================================================================
# LIFECYCLE METHODS
# =============================================================================

func _ready() -> void:
	# Connect the end turn button's pressed signal
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	
	# Hide unit info panel initially (no unit selected)
	unit_info_panel.visible = false

# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Updates the turn display with the current turn number and active faction.
## Changes the phase label color and button state based on whose turn it is.
## @param turn: The current turn number
## @param faction: The faction whose turn it is ("PLAYER" or "ENEMY")
func update_turn_display(turn: int, faction: String) -> void:
	turn_label.text = "Turn: %d" % turn
	
	if faction == "PLAYER":
		phase_label.text = "Your Turn"
		phase_label.add_theme_color_override("font_color", Color.GREEN)
		end_turn_button.disabled = false
	else:
		phase_label.text = "Enemy Turn"
		phase_label.add_theme_color_override("font_color", Color.RED)
		end_turn_button.disabled = true


## Updates the unit information panel with the selected unit's data.
## Hides the panel if no unit is selected.
## @param unit: The unit to display information for (or null to hide)
func update_unit_display(unit) -> void:
	if not unit:
		# No unit selected - hide the panel
		unit_info_panel.visible = false
		return
	
	# Show the unit info panel
	unit_info_panel.visible = true
	
	# Update name and type labels
	if unit.unit_data:
		unit_name_label.text = unit.unit_data.unit_name
		unit_type_label.text = "[%s] - %s" % [unit.unit_data.unit_type, unit.unit_data.faction]
	else:
		unit_name_label.text = "Unknown Unit"
		unit_type_label.text = unit.unit_type
	
	# Update stats label with current values
	unit_stats_label.text = "HP: %d/%d\nATK: %d\nDEF: %d\nSPD: %d" % [
		unit.current_hp,
		unit.max_hp,
		unit.current_atk,
		unit.current_def,
		unit.current_speed
	]
	
	# Build status text based on unit's action state
	var status_text: String = ""
	if unit.has_moved:
		status_text += "Moved "
	if unit.has_attacked:
		status_text += "Attacked "
	if not unit.has_moved and not unit.has_attacked:
		status_text = "Ready!"
	
	unit_status_label.text = status_text

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

## Called when the end turn button is pressed.
## Emits the end_turn_pressed signal for the game manager to handle.
func _on_end_turn_button_pressed() -> void:
	end_turn_pressed.emit()
