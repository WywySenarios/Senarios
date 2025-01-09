class_name Entity extends Card

@export var health : float = 1
@export var hpr : float = 0
@export var shield : float = 0
var attackMultiplier # multiplicative
var attackBonus # linear---added after attack multiplier

var defenseMultiplier # divides damage done to the current card
var defenseBonus # linear---danage reduction after defense multiplier
@export var aggressive : bool = true
var statusEffects # status effects that currently apply to this card
@export var currentMove : int = 0 # current move that is selected (index of "moves" array)
@export var moves : Array[Move]
@export var abilities : Array[Ability]

signal changeHealth(entity: Entity, oldHealth: int)
signal died(entity: Entity)

## Input is the stats that are being changed.
## Do NOT handle animation logic.
func changeStats(statChange: Dictionary):
	pass

## Returns a Dictionary containing all the information that the Card's Move wants to change.
func execute(target: Variant) -> Dictionary:
	return moves[currentMove].execute(target, self)

# TODO (add status effects and remove status effects) functions


## TODO test this function
## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
## @experimental
func serialize() -> Dictionary:
	var output: Dictionary = {
		"subtype": "Entity",
		"content": {
			"health": health,
			"hpr": hpr,
			"shield": shield,
			"attackMultiplier": attackMultiplier,
			"attackBonus": attackBonus,
			"defenseMultiplier": defenseMultiplier,
			"defenseBonus": defenseBonus,
			"aggressive": aggressive,
			# CRITICAL this will not work as intended because this attribute depends on a custom class
			"statusEffects": statusEffects,
			"currentMove": currentMove,
			# CRITICAL this will not work as intended because this attribute depends on a custom class
			"moves": moves.duplicate(),
			# CRITICAL this will not work as intended because this attribute depends on a custom class
			"abilites": abilities.duplicate(),
		},
	}
	
	# do NOT override the above data
	var superClassSerializaiton = super.serialize()
	output.merge(superClassSerializaiton, false)
	output.content.merge(superClassSerializaiton.content, false)
	return output

## TODO testing, signals
## Deserialize the dictionary and inject its data into the card this was called on.
## Calls updates only when there is a change in the values or references
## @experimental
func deserialize(_object: Dictionary) -> void:
	# ensure validity (this could be removed given that the child class usually ensures validity as well)
	if not _object.has("type") or _object.type != "Card" or not _object.has("content"):
		print_debug("An Entity was given an invalid dictionary to deserialize.")
		return
	
	# TODO implement overriding data
	#if _object.content.has("base_damage") and _object.content.base_damage != base_damage:
		#base_damage = _object.content.base_damage
		## TODO emit signal
	
	super.deserialize(_object)
