extends Node2D

## The index of the deck this card refers to.
@export var index: int = -1

## Emitted when this card is clicked, and therefore emitted when the user wishes to redraw a card.
signal clicked(card: Node2D)

# is the player's mouse hovering over this card right now?
var mouseInside: bool = false

# Called when the node enters the scene tree for the first time.
#func _ready():
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass
	

func _on_button_button_down():
	clicked.emit(self)
