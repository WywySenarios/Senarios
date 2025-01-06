extends Resource
class_name Deck

## The size of a Senarios deck is always 40.
const initialLength = 40

@export var content: Array[String] = []
var cardContents: Array[Card] = []

func ready() -> void:
	# Warn about invalid decks
	if len(content) != 40: push_warning("The following deck does not have 40 cards: ", self)
	
	# initialize cards as well
	for i in content:
		cardContents.append(load("res://resources/" + i + ".tres"))

func shuffle() -> void:
	content.shuffle()

#func addCard() -> void:
	#pass
