extends Control

# Exported variables:
## Height in tiles
@export var height: int = 5
## Width in tiles
@export var width: int = 5

const gridTileScene = preload("res://Scenes/level/grid_tile.tscn")


# Not exported variables:
## Stores references to all gridtiles
## Intends to ONLY store Node2Ds. Unfortunately, Godot does not support nested arrays with typing yet.
## Indexes should correspond EXACTLY with activeCards
## The grid tile's name is exactly the same as the index in this array, except separated by a comma (e.g. 0,0 or 3,1)
var gridTiles: Array[Array] = []

## Stores references to all cards currently on the field.
## Intends to ONLY store Node2Ds. Unfortunately, Godot does not support nested arrays with typing yet.
## Indexes should correspond EXACTLY with gridTiles
var activeCards: Array[Array] = []
## Stores the reference to the gridtile
var activeGridTile: Control
## Utility RNG to be used for visuals, where being truly random does not matter at all.
var utilityRNG = RandomNumberGenerator.new()

func _ready():
	# TODO don't hardcode this
	activeCards.resize(5)
	activeCards.fill([null, null, null, null, null])
	
	gridTiles.resize(5)
	gridTiles.fill([null, null, null, null, null])
	
	var metadata
	for i in get_children():
		metadata = i.name.split(',')
		metadata = [int(metadata[0]), int(metadata[1])]
		i.set_meta("id", metadata)
		i.get_node("Area2D").mouse_entered.connect(_on_mouse_entered_gridtile.bind(i))
		i.get_node("Area2D").mouse_exited.connect(_on_mouse_exit_gridtile.bind(i))
		
		gridTiles[metadata[0]][metadata[1]] = i

#region Old Grid Creation Code
# Called when the node enters the scene tree for the first time.
## Create grid tiles.
## Connects grid tile signals & card signals.
#func _ready() -> void:
	## stores whether or not the [height, width] has an odd number of tiles or not
	#
	#var currentGridTileRow
	#var currentCardRow
	#var currentGridTile
	#
	## make sure there are enough columns
	#self.columns = width
	#
	#for a in range(height):
		#currentGridTileRow = Array()
		#currentCardRow = Array()
		#for b in range(width):
			## create grid tile
			#currentGridTile = gridTileScene.instantiate()
			#currentGridTile.set_meta("id", [a,b])
			#currentGridTile.name = str(a) + "," + str(b)
			## allow for signals for mouse_entered & mouse_exited to pass into here, thereby decreasing the number of scripts I have to write.
			#currentGridTile.get_node("Area2D").mouse_entered.connect(_on_mouse_entered_gridtile.bind(currentGridTile))
			#currentGridTile.get_node("Area2D").mouse_exited.connect(_on_mouse_exit_gridtile.bind(currentGridTile))
			## make sure that the grid tile will actually show up and exist
			#add_child(currentGridTile)
			#currentGridTileRow.append(currentGridTile)
			#
			## when the grid is first made, there are no cards on the grid
			#currentCardRow.append(null)
		#
		#gridTiles.append(currentGridTileRow)
		#activeCards.append(currentCardRow)
	#
	#
	## Connect signals of every card inside the scene
	#for i in get_parent().get_node("Inventories").get_node("My Inventory").get_children():
		#i.place.connect(_on_card_placement)
#endregion

 #Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

## Setter for [member activegridTile]
## This function is intended for detecting where the player might place the card.
## This function should trigger when the mouse enters a grid tile.
func _on_mouse_entered_gridtile(tile: Control) -> void:
	activeGridTile = tile

## Setter for [member activeGridTile]
## This function is intended for detecting where the player might not want to place the card.
## This function should trigger when the mouse leaves a grid tile.
func _on_mouse_exit_gridtile(tile: Control) -> void:
	if activeGridTile == self:
		activeGridTile = null

## @experimental
## This function should be called whenever a player released their mouse button when dragging a card.
## This function handles events that follow when placing a card or returning the card to the player's inventory.
## This function should determine where and whether or not to place a card, call for animations, and call for sprite movement.
func _on_card_placement(card: Control) -> void:
	#print("Someone tried to play a card!: ", card)
	# tell the card to approach the activeGridTile
	if (activeGridTile != null):
		# randomize the animation time. It just adds a tiny bit more flavor!
		var animationTime = utilityRNG.randf_range(0.15, 0.35)
		
		#var cardPositionTween =
		get_tree().create_tween().tween_property(card, "global_position", activeGridTile.global_position, animationTime) # .set_ease(Tween.EASE_OUT)
		# rotate one revolution (1 rev = 2 pi)
		#get_tree().create_tween().tween_property(card, "global_rotation", (2 * PI) * 1, animationTime) # .set_ease(Tween.EASE_OUT)
		get_tree().create_tween().tween_property(card, "scale", Vector2(0.1, 0.1), animationTime)
		# Register card in the correct position
		# note: metadata "id" has y, x coordinates. They are the exact indexes of the array, so that's nice.
		var index = activeGridTile.get_meta("id")
		activeCards[index[0]][index[1]] = card
		card.set_meta("locationIndex", [index[0], index[1]])
		
		# remove the card from the inventory
		card.get_parent().removeCard(card)
		# add to the grid tile
		activeGridTile.add_child(card)
		
		# TODO activate particles for placing the card down once it's on the board (card class handles this)
		#cardPositionTween.finished.connect(card._on_card_placement)
	else: # tell the card to go back to where it came from >:(
		#print("Go back where you came from!")
		get_tree().create_tween().tween_property(card, "global_position", card.initialPos, 0.2).set_ease(Tween.EASE_OUT)
