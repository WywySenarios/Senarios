extends Control

const gridTileScene = preload("res://Scenes/level/grid_tile.tscn")


# Not exported variables:
## Stores references to all gridtiles
## Intends to ONLY store grid_tile nodes. Unfortunately, Godot does not support nested arrays with typing yet.
## Indexes should correspond EXACTLY with activeCards
## The grid tile's name is exactly the same as the index in this array, except separated by a comma (e.g. 0,0 or 3,1)
var gridTiles: Array[Array] = []

## Stores references to all cards currently on the field.
## Intends to ONLY store Controls. Unfortunately, Godot does not support nested arrays with typing yet.
## Indexes should correspond EXACTLY with gridTiles
@export var activeCards: Array[Array] = []
## Stores the reference to the gridtile
@export var activeGridTile: Control
## Utility RNG to be used for visuals, where being truly random does not matter at all.
var utilityRNG = RandomNumberGenerator.new()

## Stores the information regarding the last card placement request made to the server.
## Is null if there is no pending request.
## Please block making more requests until the last one has been fulfilled
## "card": Card node (Control)
## "gridTile": Grid Tile (Control)
var lastCardPlacementRequest = null

const cardScene: PackedScene = preload("res://scenes/level/card.tscn")

func _ready():
	# TODO don't hardcode this
	activeCards.resize(Lobby.gridHeight)
	for i in len(activeCards):
		var arrayToAdd = []
		arrayToAdd.resize(Lobby.gridWidth)
		# WARNING CRITICAL make sure that the above statment is actually creating new arrays.
		activeCards[i] = arrayToAdd
	
	gridTiles.resize(Lobby.gridHeight)
	for i in len(gridTiles):
		var arrayToAdd = []
		arrayToAdd.resize(Lobby.gridWidth)
		# WARNING CRITICAL make sure that the above statment is actually creating new arrays.
		gridTiles[i] = arrayToAdd
	
	var metadata
	for i in get_children():
		metadata = i.name.split(',')
		if len(metadata) != 2 or not i is Control: # ONLY deal with properly named Control nodes
			continue
		
		metadata = [int(metadata[0]), int(metadata[1])]
		i.set_meta("id", metadata.duplicate() as Array[int])
		i.get_node("Area2D").mouse_entered.connect(_on_mouse_entered_gridtile.bind(i))
		i.get_node("Area2D").mouse_exited.connect(_on_mouse_exit_gridtile.bind(i))
		
		gridTiles[metadata[0]][metadata[1]] = i
	
	# link to server
	Lobby.gridTiles = gridTiles
	Lobby.activeCards = activeCards

## Setter for [member activegridTile]
## This function is intended for detecting where the player might place the card.
## This function should trigger when the mouse enters a grid tile.
func _on_mouse_entered_gridtile(tile: Control) -> void:
	activeGridTile = tile

## Setter for [member activeGridTile]
## This function is intended for detecting where the player might not want to place the card.
## This function should trigger when the mouse leaves a grid tile.
func _on_mouse_exit_gridtile(tile: Control) -> void:
	if activeGridTile == tile:
		activeGridTile = null

## @experimental
## This function should be called whenever a player released their mouse button when dragging a card.
## This function handles events that follow when placing a card or returning the card to the player's inventory.
## This function should determine where and whether or not to place a card, call for animations, and call for sprite movement.
func _on_card_placement(card: Control) -> void:
	#print("Someone tried to play a card!: ", card)
	# tell the card to approach the activeGridTile
	# you also have to place the card in the right spot
	print(activeGridTile != null)
	print(Lobby.playerNumbers[Lobby.myID])
	if activeGridTile != null:
		print(Lobby.findGridTileOwner(activeGridTile.get_meta("id") as Array[int]))
	if (activeGridTile != null) and Lobby.playerNumbers[Lobby.myID] == Lobby.findGridTileOwner(activeGridTile.get_meta("id")):
		lastCardPlacementRequest = {
			"card": card,
			"gridTile": activeGridTile
		}
		
		var activeGridTileMetadata = activeGridTile.get_meta("id")
		var data: Array[int] = [int(activeGridTileMetadata[0]), int(activeGridTileMetadata[1])]
		#print_debug(card.card.serialize())
		Lobby.requestCardPlacement.rpc_id(1, Lobby.myID, card.card.serialize(), data)

## Called when the server approves a card placement request
## @experimental
func approvedCardPlacementRequest(id: int, _card: Dictionary, location: Array[int]) -> void:
	var gridTile: Control = gridTiles[location[0]][location[1]]
	var card: Card = Lobby.deserialize(_card)
	if id == Lobby.myID: # if this card is mine,
		var inventoryCardNode = lastCardPlacementRequest.card
		
		# randomize the animation time. It just adds a tiny bit more flavor!
		var animationTime = utilityRNG.randf_range(0.15, 0.35)
		
		var cardPositionTween = get_tree().create_tween()
		cardPositionTween.tween_property(inventoryCardNode, "global_position", gridTile.global_position, animationTime) # .set_ease(Tween.EASE_OUT)
		# rotate one revolution (1 rev = 2 pi)
		#get_tree().create_tween().tween_property(card, "global_rotation", (2 * PI) * 1, animationTime) # .set_ease(Tween.EASE_OUT)
		cardPositionTween.tween_property(inventoryCardNode, "scale", Vector2(0, 0), animationTime)
		cardPositionTween.tween_callback(inventoryCardNode.queue_free)
		
		# remove the card from the inventory
		inventoryCardNode.get_parent().removeCard(inventoryCardNode)
	else: # this is not my card,
		# remove a card from the opponent's inventory (their inventory size decreased)
		get_parent().get_node("Inventories/Far Inventory").removeCard(_card)
	#gridTile.animationSummon(location, card)

## Called when the server disapproves your card placement request
func disapprovedCardPlacementRequest():
	print("Disapproved")
	lastCardPlacementRequest = null
	# TODO

#func destroyCard(target: Variant):
	## if we are destroying a grid tile's card,
	#if target is Array:
		#activeCards[target[0]][target[1]] = null
