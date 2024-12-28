extends Control

# Exported variables:
## @experimental
@export var height: int = 5
## @experimental
@export var width: int = 5
## Tile width in pixels
@export var tileLength: int = 150
## Margin between gridtiles in pixels.
@export var margin: int = 15

const gridTileScene = preload("res://Scenes/level/grid_tile.tscn")


# Not exported variables:
## Stores references to all gridtiles
## Intends to ONLY store Node2Ds. Unfortunately, Godot does not support nested arrays with typing yet.
## Indexes should correspond EXACTLY with activeCards
var gridTiles: Array[Array] = []

## Stores references to all cards currently on the field.
## Intends to ONLY store Node2Ds. Unfortunately, Godot does not support nested arrays with typing yet.
## Indexes should correspond EXACTLY with gridTiles
var activeCards: Array[Array] = []
## Stores the reference to the gridtile
var activeGridTile: Node2D
## Utility RNG to be used for visuals, where being truly random does not matter at all.
var utilityRNG = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
## Create grid tiles.
## Connects grid tile signals & card signals.
func _ready() -> void:
	# stores whether or not the [height, width] has an odd number of tiles or not
	var oddTiles: Array[bool] = [height % 2 == 1, width % 2 == 1]
	
	var currentGridTileRow
	var currentCardRow
	var currentGridTile
	var distanceFromCenter = 0 # in # of cards
	for a in range(height):
		currentGridTileRow = Array()
		currentCardRow = Array()
		for b in range(width):
			# create grid tile
			currentGridTile = gridTileScene.instantiate()
			currentGridTile.set_meta("id", [a,b])
			# position grid tile correctly:
			if (oddTiles[1]): # width is odd
				
				# Use integer division and add one to find middle.
				# Counteract index starting at 0 by adding 1 at the end.
				@warning_ignore("integer_division")
				distanceFromCenter = b - (width / 2 + 1) + 1
				
				# default pos + # of tiles * (gap + tile)
				currentGridTile.position.x = distanceFromCenter * (margin + tileLength)
			else: # width is even
				
				# subtract 0.5 because no card is at position (0,0). IDK why it works, but it does!
				# Counteract index starting at 0 by adding 1 at the end.
				@warning_ignore("integer_division")
				distanceFromCenter = b - (width / 2) - 0.5 + 1
				
				# 0.5 * (gap + tile) + # of tiles * (gap + tile)
				# 0.5 is baked in to # of tiles due to the 0.5 being subtracted in the "distanceFromCenter" variable. :D
				@warning_ignore("integer_division")
				currentGridTile.position.x = distanceFromCenter * (margin + tileLength)
			if (oddTiles[0]): # height is odd, similar logic to width
				@warning_ignore("integer_division")
				distanceFromCenter = a - (height / 2 + 1) + 1
				
				@warning_ignore("integer_division")
				currentGridTile.position.y = distanceFromCenter * (margin + tileLength)
			else: # height is even, similar logic to width
				@warning_ignore("integer_division")
				distanceFromCenter = a - (width / 2) - 0.5 + 1
				
				currentGridTile.position.y = distanceFromCenter * (margin + tileLength)
			# allow for signals for mouse_entered & mouse_exited to pass into here, thereby decreasing the number of scripts I have to write.
			currentGridTile.get_node("Area2D").mouse_entered.connect(_on_mouse_entered_gridtile.bind(currentGridTile))
			currentGridTile.get_node("Area2D").mouse_exited.connect(_on_mouse_exit_gridtile.bind(currentGridTile))
			# make sure that the grid tile will actually show up and exist
			add_child(currentGridTile)
			currentGridTileRow.append(currentGridTile)
			
			# when the grid is first made, there are no cards on the grid
			currentCardRow.append(null)
		
		gridTiles.append(currentGridTileRow)
		activeCards.append(currentCardRow)
	
	
	# Connect signals of every card inside the scene
	for i in get_parent().get_node("Inventories").get_node("My Inventory").get_children():
		i.place.connect(_on_card_placement)


 #Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

## Setter for [member activegridTile]
## This function is intended for detecting where the player might place the card.
## This function should trigger when the mouse enters a grid tile.
func _on_mouse_entered_gridtile(tile: Node2D) -> void:
	activeGridTile = tile

## Setter for [member activeGridTile]
## This function is intended for detecting where the player might not want to place the card.
## This function should trigger when the mouse leaves a grid tile.
func _on_mouse_exit_gridtile(tile: Node2D) -> void:
	activeGridTile = null

## @experimental
## @deprecated: use _on_card_placement
## This function should be called when the player releases their mouse button when dragging a card.
## This function returns true if the player wishes to play a card. It returns false otherwise.
func requestPlacement(card: Node2D) -> bool:
	print("someone requested a card placement! Should the card get placed? ", activeGridTile != null)
	
	return activeGridTile != null

## @experimental
## This function should be called whenever a player released their mouse button when dragging a card.
## This function handles events that follow when placing a card or returning the card to the player's inventory.
## This function should determine where and whether or not to place a card, call for animations, and call for sprite movement.
func _on_card_placement(card: Node2D) -> void:
	#print("Someone tried to play a card!: ", card)
	# tell the card to approach the activeGridTile
	if (activeGridTile != null):
		# randomize the animation time. It just adds a tiny bit more flavor!
		var animationTime = utilityRNG.randf_range(0.15, 0.35)
		
		var cardPositionTween = get_tree().create_tween().tween_property(card, "global_position", activeGridTile.global_position, animationTime).set_ease(Tween.EASE_OUT)
		# rotate one revolution (1 rev = 2 pi)
		get_tree().create_tween().tween_property(card, "global_rotation", (2 * PI) * 1, animationTime).set_ease(Tween.EASE_OUT)
		# Register card in the correct position
		# note: metadata "id" has y, x coordinates. They are the exact indexes of the array, so that's nice.
		var index = activeGridTile.get_meta("id")
		activeCards[index[0]][index[1]] = card
		card.set_meta("locationIndex", [index[0], index[1]])
		
		# activate particles for placing the card down once it's on the board (card class handles this)
		cardPositionTween.finished.connect(card._on_card_placement)
	else: # tell the card to go back to where it came from >:(
		#print("Go back where you came from!")
		get_tree().create_tween().tween_property(card, "global_position", card.initialPos, 0.2).set_ease(Tween.EASE_OUT)
