# Board.gd
# Manages the tactical game board for Warlord's Gambit.
# This script creates a visual 10x10 grid using ColorRect nodes for rapid prototyping.
# No TileMapLayer is needed - tiles are drawn programmatically.
#
# COORDINATE SYSTEM:
# - Grid coordinates: Vector2i(x, y) where x is column (0-9), y is row (0-9)
# - World coordinates: Vector2(x, y) in pixels
# - Origin (0,0) is top-left corner
# - grid_data[row][col] = grid_data[y][x] stores what's on each tile
#
# Usage: Attach this script to a Node2D in your board scene

extends Node2D

# ============================================================================
# CONSTANTS
# ============================================================================

## Number of tiles in each direction (10x10 board)
const BOARD_SIZE: int = 10

## Size of each tile in pixels (64x64)
const TILE_SIZE: int = 64

# ============================================================================
# PROPERTIES
# ============================================================================

## 2D array storing what's on each tile (units, terrain, etc.)
## Access with grid_data[row][col] or grid_data[y][x]
## null = empty tile, otherwise stores reference to unit or terrain data
var grid_data: Array = []

## Currently selected grid position (-1,-1 means nothing selected)
var selected_position: Vector2i = Vector2i(-1, -1)

## Array of ColorRect nodes that make up the visual board
## Used to differentiate base tiles from highlight overlays
var tile_rects: Array = []

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when a valid tile is clicked
## @param grid_pos: The grid coordinates of the clicked tile
signal tile_clicked(grid_pos: Vector2i)

# ============================================================================
# INITIALIZATION
# ============================================================================

## Called when the node enters the scene tree
## Sets up the visual board and initializes the data structure
func _ready() -> void:
	create_visual_board()
	initialize_grid_data()
	print("Board initialized: ", BOARD_SIZE, "x", BOARD_SIZE, " grid")
	tile_clicked.connect(_on_tile_clicked)

func _on_tile_clicked(grid_pos: Vector2i) -> void:
	print("Tile clicked signal received at: ", grid_pos)


## Creates the visual representation of the board using ColorRect nodes
## Generates a checkerboard pattern for easy visualization
func create_visual_board() -> void:
	# Loop through each row and column to create tiles
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			# Create a new ColorRect for this tile
			var tile = ColorRect.new()
			tile.size = Vector2(TILE_SIZE, TILE_SIZE)
			tile.position = Vector2(col * TILE_SIZE, row * TILE_SIZE)
			
			# Apply checkerboard pattern for visual clarity
			# Light tiles where (row + col) is even, dark tiles where odd
			if (row + col) % 2 == 0:
				tile.color = Color(0.9, 0.9, 0.8) # Light cream color
			else:
				tile.color = Color(0.7, 0.7, 0.6) # Darker tan color
			
			# Add tile to scene and track it in our array
			add_child(tile)
			tile_rects.append(tile)


## Initializes the grid_data 2D array with null values
## Each cell starts empty (null) and can later hold unit references
func initialize_grid_data() -> void:
	grid_data.clear() # Clear any existing data
	
	for row in range(BOARD_SIZE):
		var row_data: Array = []
		for col in range(BOARD_SIZE):
			row_data.append(null) # Empty tile
		grid_data.append(row_data)

# ============================================================================
# COORDINATE CONVERSION
# ============================================================================

## Converts world (pixel) position to grid coordinates
## @param world_pos: Position in pixels (e.g., mouse position)
## @return: Grid coordinates as Vector2i (may be out of bounds!)
func world_to_grid(world_pos: Vector2) -> Vector2i:
	# Integer division to get grid cell
	# Example: pixel 150 / 64 = 2 (third column, index 2)
	var grid_x: int = int(world_pos.x / TILE_SIZE)
	var grid_y: int = int(world_pos.y / TILE_SIZE)
	return Vector2i(grid_x, grid_y)


## Converts grid coordinates to world (pixel) position
## Returns the CENTER of the tile (useful for placing units)
## @param grid_pos: Grid coordinates
## @return: World position at tile center in pixels
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	# Multiply by tile size and add half to get center
	# Example: grid (2, 3) -> pixel (2*64 + 32, 3*64 + 32) = (160, 224)
	var world_x: float = grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0
	var world_y: float = grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0
	return Vector2(world_x, world_y)

# ============================================================================
# GRID VALIDATION & DATA ACCESS
# ============================================================================

## Checks if a grid position is within the board boundaries
## @param grid_pos: Position to validate
## @return: true if position is valid (0-9 for both x and y)
func is_valid_position(grid_pos: Vector2i) -> bool:
	return (grid_pos.x >= 0 and grid_pos.x < BOARD_SIZE and
			grid_pos.y >= 0 and grid_pos.y < BOARD_SIZE)


## Gets whatever is stored at a grid position
## @param grid_pos: Grid coordinates to check
## @return: Data at that position (unit reference, null if empty, etc.)
func get_tile_data(grid_pos: Vector2i):
	if is_valid_position(grid_pos):
		# Note: grid_data is [row][col] = [y][x]
		return grid_data[grid_pos.y][grid_pos.x]
	return null


## Stores data at a grid position
## Use this to place units, mark terrain, etc.
## @param grid_pos: Grid coordinates
## @param data: What to store (unit reference, terrain type, etc.)
func set_tile_data(grid_pos: Vector2i, data) -> void:
	if is_valid_position(grid_pos):
		grid_data[grid_pos.y][grid_pos.x] = data

# ============================================================================
# TILE HIGHLIGHTING
# ============================================================================

## Highlights multiple tiles with a semi-transparent color overlay
## Used to show valid moves, attack range, selected units, etc.
## @param positions: Array of grid positions to highlight
## @param color: Base color for highlights (will be made semi-transparent)
func highlight_tiles(positions: Array[Vector2i], color: Color) -> void:
	# Clear any existing highlights first
	clear_highlights()
	
	# Add the highlights
	add_highlights(positions, color)


## Adds highlights without clearing existing ones
## Use this to add multiple colors of highlights
## @param positions: Array of grid positions to highlight
## @param color: Base color for highlights (will be made semi-transparent)
func add_highlights(positions: Array[Vector2i], color: Color) -> void:
	for pos in positions:
		if is_valid_position(pos):
			# Create a new ColorRect overlay for each highlighted tile
			var highlight = ColorRect.new()
			highlight.size = Vector2(TILE_SIZE, TILE_SIZE)
			highlight.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
			
			# Make the highlight semi-transparent (50% opacity)
			highlight.color = Color(color.r, color.g, color.b, 0.5)
			
			# IMPORTANT: Let mouse clicks pass through the highlight
			# Otherwise highlights would block tile_clicked detection
			highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			add_child(highlight)


## Removes all highlight overlays from the board
## Keeps the base tile_rects intact
func clear_highlights() -> void:
	# Get all children and remove any ColorRect that isn't a base tile
	var children = get_children()
	for child in children:
		if child is ColorRect and not child in tile_rects:
			child.queue_free()

# ============================================================================
# INPUT HANDLING
# ============================================================================

## Handles input events for tile clicking
## Converts mouse clicks to grid coordinates and emits tile_clicked signal
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Check for left mouse button press
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Get mouse position and convert to local coordinates
			# This accounts for the Board node's position in the scene
			var mouse_pos = get_global_mouse_position()
			var local_pos = to_local(mouse_pos)
			
			# Convert pixel position to grid coordinates
			var grid_pos = world_to_grid(local_pos)
			
			# Only emit signal if click was within board bounds
			if is_valid_position(grid_pos):
				selected_position = grid_pos
				tile_clicked.emit(grid_pos)
				print("Tile clicked: ", grid_pos)
