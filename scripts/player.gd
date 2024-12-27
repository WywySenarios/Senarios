extends Resource
class_name Player

## Self-ascribed name. Defaults to ???
@export var name: String = "???"
## Non-optional variable containing the player ID. The default value (no explicitly assigned playerID) is -1.
@export var id : int = -1
@export var energy: int = 0
#@export var statusEffects: 
@export var isTheirTurn: bool = false
## The inventory is an array containing the cards in their inventory.
## This should be used by the respective player and the server.
@export var inventory: Array[Card] = []
var inventoryLength

## Player number. Player 1 goes first, Player 2 goes second, etc.
@export var playerNumber: int = -1
## The amount of energy the player gains upon the next turn starting
@export var energyRate: int = 1

## The contents of this variable should ONLY be used by the server.
@export var deck: Deck
var deckLength: int

func _ready():
	if deck != null:
		deckLength = len(deck)
	
	if inventory != null:
		inventoryLength = len(inventory)
