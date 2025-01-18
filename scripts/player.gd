extends Resource
class_name Player

## Self-ascribed name. Defaults to ???
@export var name: String = "???"
## Non-optional variable containing the player ID. The default value (no explicitly assigned playerID) is -1.
@export var id : int = -1
## Each player starts with 1 energy.
@export var energy: int = 10
@export var health: int = 20
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

signal died(playerNumber: int)
signal healthChanged(playerNumber: int, oldHealth: int)

func ready():
	if deck != null:
		deckLength = len(deck.content)
	
	if inventory != null:
		inventoryLength = len(inventory)
	
	died.connect(Lobby.gameEnd)

func serializedInventory():
	var output: Array[Dictionary] = []
	for i in inventory:
		output.append(i.serialize())
	
	return output


## Input is the stats that are being changed.
## Do NOT handle animation logic.
func changeStats(target: Variant, _cause: Variant, statChange: Dictionary, directAttack: bool):
	# proceed only if the relevant player has been hit
	if not target is int or target != playerNumber:
		return
	
	var oldStats = {}
	
	if statChange.has("health"):
		oldStats["health"] = health
		health += statChange.health
		healthChanged.emit(playerNumber, oldStats.health)
	
	if health <= 0:
		died.emit(playerNumber)
