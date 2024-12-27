extends Node2D

## Array of cards containing the cards the player has at the start of the match
@export var cardArray: Array[Card] = []

## specifies whether or not this is the current player's inventory or not
@export var isMyInventory: bool = false


## Inventory Width in pixels
const inventoryWidth = 1200

## Gap size between cards in pixels
var gapSize: int = 50

## The width of a card in pixels
var cardWidth: int = 250

var cards: Array[Node2D] = []

# Avoid having to load it again and again, thus saving a bit of runtime.
const cardScene = preload("res://Scenes/card.tscn")

## Inititalizes and places cards to be ready to play!
## Called when the node enters the scene tree for the first time.
## Also determines whether or not the cards are faceup or facedown, based on [member Inventory.isMyInventory] (<- check if this doc comment is valid later on)
## @experimental
func _ready():
	# Make a bunch of cards as requested by the cardArray
	var currentCard
	for i in range(len(cardArray)):
		currentCard = cardScene.instantiate()
		currentCard.faceup = isMyInventory # faceup ONLY if it's the current player's inventory
		currentCard.card = cardArray[i]
		# Card name = Card [i] (e.g. Card 1)
		currentCard.name = "Card " + str(i)
		#currentCard.position = Vector2(0,0)
		
		
		# Make the current card actually exist
		cards.append(currentCard)
		add_child(currentCard)
	
	# Send cardArray to garbage collection
	cardArray.clear()
	
	# reposition cards because the cards have just been initialized
	repositionCards()

## Repositions cards. To be called when a card is removed or added to the inventory
## @experimental
func repositionCards():
	
	if (len(cards) % 2 == 0): # even number of cards
		# T
		
		#IDK why the index corrections work, but they do
		@warning_ignore("integer_division")
		var indexCorrectionPositive = len(cards) / 2 - 2
		@warning_ignore("integer_division")
		var indexCorrectionNegative = -(len(cards) / 2 - 1)
		
		# loops through the absolute value of the distance from the center
		@warning_ignore("integer_division")
		for distanceFromCenter: int in range(1, len(cards) / 2 + 1):			
			cards[indexCorrectionPositive + distanceFromCenter].position.x = (distanceFromCenter * (gapSize + cardWidth) - cardWidth / 2.0)
			cards[indexCorrectionNegative + distanceFromCenter].position.x = -(distanceFromCenter * (gapSize + cardWidth) - cardWidth / 2.0)
			
			#print("Inventory card positions: ", distanceFromCenter, " ", indexCorrectionPositive + distanceFromCenter, " ", cards[indexCorrectionPositive + distanceFromCenter].position, " ", cards[indexCorrectionPositive + distanceFromCenter].global_position)
			#print("Inventory card positions: ", -distanceFromCenter, " ", indexCorrectionNegative + distanceFromCenter, " ", cards[indexCorrectionNegative + distanceFromCenter].position, " ", cards[indexCorrectionNegative + distanceFromCenter].global_position)
	else: # odd number of cards
		@warning_ignore("integer_division")
		var indexCorrection = len(cards) / 2
		
		for distanceFromCenter: int in range(-indexCorrection, indexCorrection + 1):
			# the actual formula should be 0.5 * cardWidth + 1 * gapSize + 0.5 * cardWidth
			cards[distanceFromCenter + indexCorrection].position.x = distanceFromCenter * (gapSize + cardWidth)
			#print("Inventory card positions: ", distanceFromCenter, " ", distanceFromCenter + indexCorrection, " ", cards[distanceFromCenter + indexCorrection].global_position)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass
