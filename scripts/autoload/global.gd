extends Node

var screen_size: Vector2
## stores the current ID of the player that the current client is.
var id: int = -1

## Holds an empty card scene. NOTE: specify whether or not isInInventory is true or false in order to get expected results.
var emptyCardScene: Control
@onready var emptyCard: Card = load("res://resources/empty.tres")

var focusedCard: Control = null
signal updatedFocusedCard(card: Control)

func _ready():
	emptyCardScene = preload("res://scenes/level/card.tscn").instantiate()
	emptyCardScene.card = emptyCard

func reprocess_screen_size():
	screen_size = get_viewport().get_visible_rect().size
	get_tree().call_group("Screen Proportion Dependant", "reprocess_screen_size")

func focuseCard(card: Control):
	if focusedCard == null:
		focusedCard = card
		updatedFocusedCard.emit(focusedCard)
		
func unfocusCard(card: Control):
	if focusedCard == card:
		focusedCard = null
		updatedFocusedCard.emit(focusedCard)

## Creates a card out of a dictionary of data.
## @deprecated
func createCard(arg: Dictionary) -> Card:
	# TODO ensure valid input?
	if not arg.has("subtype"):
		return null
	
	match arg.subtype:
		"Entity":
			return Entity.new(arg)
		"Special":
			return null
		"Environment":
			return null
		_:
			return null

## Loads a card based on the card ID given. This is intended to make file pathing changes easier.
func loadCard(cardID: String):
	return load("res://resources/" + cardID + ".tres")
