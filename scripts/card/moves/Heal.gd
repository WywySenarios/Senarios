class_name Heal extends Move
## Generic Heal move.
## May heal a card directly.
## TODO heal all cards meeting certain criteria by passing in a Dictionary as _targets.

## The base heal, before additive and multiplicative healing bonuses (and therefore also before additive and multiplicative healing bonuses/reductions)
## POSITIVITY: A positive integer leads to the target gaining health.
@export var base_heals : int = 1

func getType() -> String:
	return "AttackDirect"

## Adds health to an Entity
func execute(_target: Variant, attacker: Card) -> Dictionary:
	if (attacker is Entity) or (attacker is Special):
		# account for healing bonuses
		var heals = base_heals  # * attacker.attackMultiplier) + attacker.attackBonus
		var target
		
		if _target is Array[int]: # in the case that it's an Entity and might have healing bonuses/reductions,
			target = Lobby.activeCards[_target[0]][_target[1]]
			
			if target is Control:
				target = target.card
			
			# type safety
			if target == null:
				return {}
			
			# Integer division is intended. Welcome to the world of game mechanics, I guess.
			@warning_ignore("integer_division")
			#heals /= target.defenseMultiplier
			#if heals > target.defenseBonus: # if the healing is more than 0,
				#heals -= target.defenseBonus
			#else:
				## WARNING animations for 0 hp change may be removed in the future.
				#heals = 0 # we still want to display that a card got healed, even if they didn't gain any health because of it.
		elif _target is int: # if the target is a player,
			pass
			
		return {
			"target": _target,
			"cause": attacker.serialize(), # TODO save runtime by passing this in or adding this in in another stage/function
			"type": "Attack",
			"directAttack": true,
			"statChange": {
				# account for attack bonuses AND the defense bonuses of the target
				"health": heals,
			}
		}
	else:
		return {}

## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
func serialize() -> Dictionary:
	var output: Dictionary = {
		"subtype": "Heal",
		"content": {
			"base_heals": base_heals,
		},
	}
	
	# do NOT override the above data
	var superClassSerializaiton = super.serialize()
	output.merge(superClassSerializaiton, false)
	output.content.merge(superClassSerializaiton.content, false)
	return output

## Deserialize the dictionary and inject its data into the card this was called on.
## Calls updates only when there is a change in the values or references
func deserialize(_object: Dictionary) -> void:
	# ensure validity (this could be removed given that the child class usually ensures validity as well)
	if not _object.has("type") or _object.type != "Move" or not _object.has("content"):
		return
	
	if _object.content.has("base_heals") and _object.content.base_heals != base_heals:
		base_heals = _object.content.base_heals
		# TODO emit signal
	
	super.deserialize(_object)
