class_name Entity extends Card

@export var health : int = 1
@export var hpr : int = 0
@export var shield : int = 0

var defenseMultiplier: float = 1 # divides damage done to the current card
var defenseBonus: int = 0 # linear---danage reduction after defense multiplier
@export var aggressive : bool = true
# TODO make this exportable 
var statusEffects # status effects that currently apply to this card

## Runtime variable used to store the serialized moves. DO NOT use this for any purposes outside of this class.
var serializedMoves: Array[Dictionary]
@export var abilities : Array[Ability]

var location = [-1, -1]

## @deprecated
signal died(entity: Entity)

## Input is the stats that are being changed.
## Do NOT handle animation logic.
func changeStats(statChange: Dictionary):
	var oldStats = {}
	if statChange.has("health"):
		oldStats["health"] = health
		health += statChange.health
		changeHealth.emit(self, oldStats["health"])
		#print("HEALTH: ", health, " OLD HEALTH: ", oldStats["health"], " CARD ID: ", cardID, " STAT CHANGE: ", statChange.health)
	
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

## Returns a Dictionary containing all the information that the Card's Move wants to change.
func execute(target: Variant) -> Dictionary:
	return move.execute(target, self)

# TODO (add status effects and remove status effects) functions


## TODO test this function
## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
## @experimental
func serialize() -> Dictionary:
	
	# TODO abilities
	# TODO status effects
	
	var output: Dictionary = {
		"subtype": "Entity",
		"content": {
			"health": health,
			"hpr": hpr,
			"shield": shield,
			"defenseMultiplier": defenseMultiplier,
			"defenseBonus": defenseBonus,
			"aggressive": aggressive,
			# CRITICAL this will not work as intended because this attribute depends on a custom class
			"statusEffects": statusEffects,
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
	
	if _object.content.has("health") and _object.content.health != health:
		health = _object.content.health
		# TODO emit signal
		
	if _object.content.has("hpr") and _object.content.hpr != hpr:
		hpr = _object.content.hpr
		# TODO emit signal
		
	if _object.content.has("shield") and _object.content.shield != shield:
		shield = _object.content.shield
		# TODO emit signal
	
	if _object.content.has("defenseMultiplier") and _object.content.defenseMultiplier != defenseMultiplier:
		defenseMultiplier = _object.content.defenseMultiplier
		# TODO emit signal
	
	if _object.content.has("defenseBonus") and _object.content.defenseBonus != defenseBonus:
		defenseBonus = _object.content.defenseBonus
		# TODO emit signal
	
	if _object.content.has("aggressive") and _object.content.aggressive != aggressive:
		aggressive = _object.content.aggressive
		# TODO emit signal
		
	if _object.content.has("statusEffects") and _object.content.statusEffects != statusEffects:
		statusEffects = _object.content.statusEffects
		# TODO emit signal
	
	# TODO abilities
	# TODO status effects
	
	super.deserialize(_object)
