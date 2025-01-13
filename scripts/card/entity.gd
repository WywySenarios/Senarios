class_name Entity extends Card

@export var health : int = 1
@export var hpr : int = 0
@export var shield : int = 0
var attackMultiplier: float = 1 # multiplicative
var attackBonus: int = 0 # linear---added after attack multiplier

var defenseMultiplier: float = 1 # divides damage done to the current card
var defenseBonus: int = 0 # linear---danage reduction after defense multiplier
@export var aggressive : bool = true
# TODO make this exportable 
var statusEffects # status effects that currently apply to this card
@export var currentMove : int = 0 # current move that is selected (index of "moves" array)
@export var moves : Array[Move]
var serializedMoves: Array[Dictionary]
@export var abilities : Array[Ability]

var location = [-1, -1]

#signal changeHealth(entity: Entity, oldHealth: int)
## @deprecated
signal died(entity: Entity)

## Input is the stats that are being changed.
## Do NOT handle animation logic.
func changeStats(statChange: Dictionary):
	if statChange.has("health"):
		health += statChange.health
	
	# TODO implement more things to change
	if health <= 0:
		died.emit(self)
		
		Lobby.nextAnimations.append({
			"target": location,
			"cause": null,
			"type": "Kill",
			"directAttack": false, # not relevant, so any Boolean is OK.
			# use default animation duration
			"statChange": {} # not relevant, so any Dictionary is OK.
		})
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
	var serializedMoves: Array[Dictionary] = []
	for i in moves:
		serializedMoves.append(i.serialize())
	
	# TODO abilities
	# TODO status effects
	
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
			"moves": serializedMoves,
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
	
	# TODO fix checking if the data is the same (serializedMoves is not always updated correctly)
	if _object.content.has("moves") and serializedMoves != _object.content.moves:
		moves = []
		for i in _object.content.moves:
			moves.append(Lobby.deserialize(i))
		# TODO emit signals
	
	# TODO abilities
	# TODO status effects
	
	super.deserialize(_object)
