extends Control

## The index of the deck this card refers to.
@export var index: int = -1

## Emitted when this card is clicked, and therefore emitted when the user wishes to redraw a card.
signal clicked(card: Control)

# is the player's mouse hovering over this card right now?
var mouseInside: bool = false

# Called when the node enters the scene tree for the first time.
#func _ready():
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func reassignCard(_index: int, card: Card):
	index = _index
	$"Frontside/card_head".texture = card.image

func swapCard():
	if 0 <= index and index <= 3: # do NOT refresh the card after it has already been refreshed once
		clicked.emit(self)
