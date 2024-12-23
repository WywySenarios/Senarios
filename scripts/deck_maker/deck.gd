extends Resource
class_name Deck

## The size of a Senarios deck is always 40.
const initialLength = 40

@export var content: Array[Card] = []

func _ready():
	if len(content) != 40: push_warning("The following deck does not have 40 cards: ", self)
