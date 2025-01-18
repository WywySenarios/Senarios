extends Resource
class_name Deck

## The size of a Senarios deck is always 40.
const initialLength = 40
@export var name : String
@export var content: Array[String] = []
#var cards: Array[Card] = []
## Dictionary that stores the Resources of this deck. This is intended to save runtime, I guess.
var cards: Dictionary = {}

func ready() -> void:
	# Warn about invalid decks
	if len(content) != 40: push_warning("The following deck does not have 40 cards: ", self)
	
	# initialize cards as well
	for i in content:
		if not cards.has(i):
			cards[i] = load("res://resources/" + i + ".tres")

func shuffle() -> void:
	content.shuffle()

## Removes a card from the deck (hopefully after you drew the card).
## Returns true if the player's deck is empty after the respective card is removed.
func removeCard(index: int) -> bool:
	#cards.pop_at(index)
	content.pop_at(index)
	
	return len(content) <= 0

## returns the card to be drawn from the deck, or null if it's the last card.
func drawCard(index: int) -> Card:
	var output: Card = cards[content[index]]
	
	if removeCard(index):
		return null
	else:
		return output
