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

## 2D array storing TerrainData for each tile
## Access with terrain_data[row][col] or terrain_data[y][x]
## null = no terrain assigned, otherwise stores TerrainData resource
var terrain_data: Array = []

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


## Initializes the grid_data and terrain_data 2D arrays with null values
## Each cell starts empty (null) and can later hold unit/terrain references
func initialize_grid_data() -> void:
	grid_data.clear() # Clear any existing data
	terrain_data.clear() # Clear any existing terrain
	
	# Initialize grid_data (stores units)
	for row in range(BOARD_SIZE):
		var row_data: Array = []
		for col in range(BOARD_SIZE):
			row_data.append(null) # Empty tile
		grid_data.append(row_data)
	
	# Initialize terrain_data (stores TerrainData resources)
	for row in range(BOARD_SIZE):
		var terrain_row: Array = []
		for col in range(BOARD_SIZE):
			terrain_row.append(null) # No terrain assigned yet
		terrain_data.append(terrain_row)

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
# TERRAIN MANAGEMENT
# ============================================================================

## Sets the terrain at a grid position and updates the tile's visual color
## @param grid_pos: Grid coordinates to set terrain at
## @param terrain: TerrainData resource to assign (or null to clear)
func set_terrain(grid_pos: Vector2i, terrain: TerrainData) -> void:
	if not is_valid_position(grid_pos):
		return
	
	# Store terrain data in the 2D array
	terrain_data[grid_pos.y][grid_pos.x] = terrain
	
	# Update the tile's visual appearance
	if terrain:
		update_tile_visual_color(grid_pos, terrain.color)
	else:
		# Reset to default checkerboard color if terrain is cleared
		var default_color: Color
		if (grid_pos.y + grid_pos.x) % 2 == 0:
			default_color = Color(0.9, 0.9, 0.8) # Light cream
		else:
			default_color = Color(0.7, 0.7, 0.6) # Dark tan
		update_tile_visual_color(grid_pos, default_color)


## Gets the terrain at a grid position
## @param grid_pos: Grid coordinates to check
## @return: TerrainData at that position, or null if none
func get_terrain(grid_pos: Vector2i) -> TerrainData:
	if not is_valid_position(grid_pos):
		return null
	return terrain_data[grid_pos.y][grid_pos.x]


## Updates the visual color of a tile to reflect its terrain
## Maintains checkerboard pattern by blending terrain color with base tile color
## @param grid_pos: Grid coordinates of the tile to update
## @param terrain_color: The terrain's color to apply
func update_tile_visual_color(grid_pos: Vector2i, terrain_color: Color) -> void:
	# Calculate tile index in the flat tile_rects array
	# Tiles are stored row by row: index = row * BOARD_SIZE + col
	var tile_index: int = grid_pos.y * BOARD_SIZE + grid_pos.x
	
	if tile_index >= 0 and tile_index < tile_rects.size():
		# Blend terrain color with checkerboard pattern for visual variety
		var base_brightness: float = 1.0 if (grid_pos.y + grid_pos.x) % 2 == 0 else 0.85
		var blended_color = Color(
			terrain_color.r * base_brightness,
			terrain_color.g * base_brightness,
			terrain_color.b * base_brightness,
			terrain_color.a
		)
		tile_rects[tile_index].color = blended_color


## Generates random terrain across the board for tactical variety
## Creates clusters of terrain for more realistic/interesting maps
## Avoids placing special terrain on spawn rows (0-2 for enemies, 7-9 for players)
func generate_random_terrain() -> void:
	print("[Board] Generating random terrain...")
	
	# Load terrain resources
	var plains: TerrainData = load("res://resources/terrain_types/terrain_plains.tres")
	var forest: TerrainData = load("res://resources/terrain_types/terrain_forest.tres")
	var mountain: TerrainData = load("res://resources/terrain_types/terrain_mountain.tres")
	var water: TerrainData = load("res://resources/terrain_types/terrain_water.tres")
	
	# Validate resources loaded
	if not plains:
		push_warning("[Board] Could not load terrain_plains.tres - using null terrain")
	if not forest:
		push_warning("[Board] Could not load terrain_forest.tres")
	if not mountain:
		push_warning("[Board] Could not load terrain_mountain.tres")
	if not water:
		push_warning("[Board] Could not load terrain_water.tres")
	
	# Set all tiles to plains by default
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			var pos = Vector2i(col, row)
			set_terrain(pos, plains)
	
	# Define safe zones where we won't place special terrain
	# Rows 0-2: Enemy spawn area
	# Rows 7-9: Player spawn area
	# Only place special terrain in rows 3-6 (the "battlefield")
	var min_safe_row: int = 3
	var max_safe_row: int = 6
	
	# --- GENERATE FOREST CLUSTERS (15% of battlefield tiles) ---
	# Forests provide cover and slow movement
	var forest_seeds: int = 3 # Number of forest clusters
	for i in range(forest_seeds):
		_generate_terrain_cluster(forest, min_safe_row, max_safe_row, 3, 5)
	
	# --- GENERATE MOUNTAIN CLUSTERS (10% of battlefield tiles) ---
	# Mountains provide height advantage but are slow to traverse
	var mountain_seeds: int = 2 # Number of mountain clusters
	for i in range(mountain_seeds):
		_generate_terrain_cluster(mountain, min_safe_row, max_safe_row, 2, 3)
	
	# --- GENERATE WATER TILES (8% of battlefield, more isolated) ---
	# Water blocks movement, creating tactical chokepoints
	var water_seeds: int = 2
	for i in range(water_seeds):
		_generate_terrain_cluster(water, min_safe_row, max_safe_row, 1, 3)
	
	print("[Board] Terrain generation complete!")


## Helper function to generate a cluster of terrain tiles
## Creates organic-looking terrain patches by growing from a seed point
## @param terrain: TerrainData resource to place
## @param min_row: Minimum row to place terrain (inclusive)
## @param max_row: Maximum row to place terrain (inclusive)
## @param min_size: Minimum number of tiles in cluster
## @param max_size: Maximum number of tiles in cluster
func _generate_terrain_cluster(terrain: TerrainData, min_row: int, max_row: int, min_size: int, max_size: int) -> void:
	if not terrain:
		return
	
	# Pick a random seed position within the safe zone
	var seed_col: int = randi_range(1, BOARD_SIZE - 2) # Avoid edges
	var seed_row: int = randi_range(min_row, max_row)
	var seed_pos = Vector2i(seed_col, seed_row)
	
	# Determine cluster size
	var cluster_size: int = randi_range(min_size, max_size)
	
	# Track positions to fill
	var positions_to_fill: Array[Vector2i] = [seed_pos]
	var filled_count: int = 0
	
	# Grow the cluster organically
	while filled_count < cluster_size and positions_to_fill.size() > 0:
		# Pick a random position from our list
		var index: int = randi_range(0, positions_to_fill.size() - 1)
		var pos: Vector2i = positions_to_fill[index]
		positions_to_fill.remove_at(index)
		
		# Check if position is valid and within safe zone
		if not is_valid_position(pos):
			continue
		if pos.y < min_row or pos.y > max_row:
			continue
		
		# Don't overwrite existing special terrain (only plains)
		var existing: TerrainData = get_terrain(pos)
		if existing and existing.terrain_type != "PLAINS":
			continue
		
		# Place the terrain
		set_terrain(pos, terrain)
		filled_count += 1
		
		# Add adjacent tiles as candidates for expansion (4-directional)
		var neighbors: Array[Vector2i] = [
			Vector2i(pos.x - 1, pos.y), # Left
			Vector2i(pos.x + 1, pos.y), # Right
			Vector2i(pos.x, pos.y - 1), # Up
			Vector2i(pos.x, pos.y + 1), # Down
		]
		
		# Randomly add neighbors (70% chance each for organic growth)
		for neighbor in neighbors:
			if randf() < 0.7 and neighbor not in positions_to_fill:
				positions_to_fill.append(neighbor)

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
