extends Node

var screen_size: Vector2
## stores the current ID of the player that the current client is.
var id: int = -1

## Holds an empty card scene. NOTE: specify whether or not isInInventory is true or false in order to get expected results.
var emptyCardScene: Control
@onready var emptyCard: Card = load("res://resources/empty.tres")

var focusedCard: Control = null
signal updatedFocusedCard(card: Control)
signal cardClicked(card: Control)

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

func 
