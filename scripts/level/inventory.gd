extends Container

const INVENTORY_COLOR_WYWY: Color = Color(0xf9d91e, 0.1)
const INVENTORY_COLOR_STICKMAN: Color = Color(0xe1483a, 0.1) # this color is likely to be changed later.

## specifies whether or not this is the current player's inventory or not
@export var isMyInventory: bool = false


## Inventory Width in pixels
const inventoryWidth = 1200

## Gap size between cards in pixels
var gapSize: int = 50

## The width of a card in pixels
var cardWidth: int = 250

var cards: Array[Card] = []
var cardNodes: Array[Node] = []

var cardSpawnPoint # the place where the card spawns

# Avoid having to load it again and again, thus saving a bit of runtime.
const cardScene = preload("res://scenes/level/card.tscn")

var gridNode

# not currently active: This ready function just ensures that the inventory has the right background color.
func _ready():
	# TODO change from hard coded to adaptable
	gridNode = get_parent().get_parent().get_node("Grid")
	#$Background.color = INVENTORY_COLOR_STICKMAN

func addCard(_card: Card):
	var card = cardScene.instantiate()
	# create a new card node to represent this card
	card.card = _card
	card.isInInventory = true
	# hide the card so the backend stuff isn't visible
	card.hide()
	
	# is this my card (are the contents visible or censored)?
	if not isMyInventory: # if it's not mine,
		if card.faceup: # if the card is currently visible,
			# make it not visible
			card.flipOver()
	elif not card.faceup: # if it's mine and not faceup,
		# flip over the card so that it's faceup
		card.flipOver()
	
	# add the card to the recognized list of cards
	cards.append(_card)
	cardNodes.append(card)
	
	# add the card to the inventory
	add_child(card)
	# store where it's supposed to be after the animation ends
	var finalGlobalPosition = card.global_position
	
	# set the initial position of card
	# CRITICAL throws an error if the inventory wasn't given a card spawn point (i.e. cardSpawnPoint is null)
	card.global_position = cardSpawnPoint.global_position
	
	var animation = get_tree().create_tween()
	animation.tween_property(card, "global_position", finalGlobalPosition, 0.5)
	# fallback teleport to the correct location (just in case something weird happens during the animation
	# I do this because I was tweening with the global_position,
	# if something happens in the meantime with the inventory,
	# the card ends up ending in the wrong position
	animation.tween_callback(queue_sort)
	
	# ready to show user animations
	card.show()
	
	# connect necessary signals
	card.place.connect(gridNode._on_card_placement)
	
func addCards(_cards: Array[Card]):
	var card
	var cards: Array[Container] = []
	for i in _cards:
		# create a new card node to represent this card
		card = cardScene.instantiate()
		card.card = i
		card.isInInventory = true
		
		# hide the card so the backend stuff isn't visible
		card.hide()
	
		# is this my card (are the contents visible or censored)?
		if not isMyInventory: # if it's not mine,
			if card.faceup: # if the card is currently visible,
				# make it not visible
				card.flipOver()
		elif not card.faceup: # if it's mine and not faceup,
			# flip over the card so that it's faceup
			card.flipOver()
		
		# add the card to the recognized list of cards
		cards.append(i)
		cardNodes.append(card)
		
		# add the card to the inventory
		add_child(card)
	
	queue_sort()
	
	# animation logic:
	for i in cards:
		
		# store where it's supposed to be after the animation ends
		var finalGlobalPosition = i.global_position
		
		# set the initial position of card
		# CRITICAL throws an error if the inventory wasn't given a card spawn point (i.e. cardSpawnPoint is null)
		i.global_position = cardSpawnPoint.global_position
		
		var animation = get_tree().create_tween()
		animation.tween_property(i, "global_position", finalGlobalPosition, 0.5)
		# fallback teleport to the correct location (just in case something weird happens during the animation
		# I do this because I was tweening with the global_position,
		# if something happens in the meantime with the inventory,
		# the card ends up ending in the wrong position
		animation.tween_callback(queue_sort)
		
		# ready to show user animations
		i.show()
		
		# connect necessary signals
		i.place.connect(gridNode._on_card_placement)
	
func removeCard(card: Node):
	var index = cardNodes.find(card)
	if index != -1:
		card.isInInventory = false
		Draggables.deselectCard(card) # fallback function just to ensure good behaviour of the computer program
		remove_child(cardNodes[index])
		cards.pop_at(index)
		cardNodes.pop_at(index)
