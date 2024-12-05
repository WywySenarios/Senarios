extends Node2D

var activeGridTile: Node2D
var gridTileArea2D: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in $tiles.get_children():
		# allow for signals for mouse_entered & mouse_exited to pass into here, thereby decreasing the number of scripts I have to write.
		i.get_child(1).mouse_entered.connect(_on_mouse_entered_gridtile.bind(i))
		i.get_child(1).mouse_exited.connect(_on_mouse_exit_gridtile.bind(i))
	
	for i in $Cards.get_children():
		i.place.connect(_on_card_placement)


# Called every frame. 'delta' is the elapsed time since the previous frame.
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
	print("Someone played a card!: ", card)
	# tell the card to approach the activeGridTile
	if (activeGridTile != null):
		get_tree().create_tween().tween_property(card, "position", activeGridTile.position, 0.2).set_ease(Tween.EASE_OUT)
	else: # tell the card to go back to where it came from >:(
		get_tree().create_tween().tween_property(card, "global_position", card.initialPos, 0.2).set_ease(Tween.EASE_OUT)
