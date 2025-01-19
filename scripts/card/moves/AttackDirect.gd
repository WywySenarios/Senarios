class_name AttackDirect extends Move

## The base damage, before additive and multiplicative attack bonuses (and therefore also before additive and multiplicative defensive bonuses)
## POSITIVITY: A positive integer leads to the target losing health.
@export var base_damage : int = 0

func getType() -> String:
	return "AttackDirect"

## Deducts health from the target if the attacker is able to attack.
func execute(_target: Variant, attacker: Card) -> Dictionary:
	if (attacker is Entity and attacker.aggressive) or (attacker is Special):
		# account for attack bonuses AND the defense bonuses of the target
		var damage = (base_damage * attacker.attackMultiplier) + attacker.attackBonus
		var target
		
		if _target is Array[int]:
			target = Lobby.activeCards[_target[0]][_target[1]]
			
			if target is Control:
				target = target.card
			
			# type safety
			if target == null:
				return {}
			
			# Integer division is intended. Welcome to the world of game mechanics, I guess.
			@warning_ignore("integer_division")
			damage /= target.defenseMultiplier
			if damage > target.defenseBonus: # if the damage is more than 0,
				damage -= target.defenseBonus
			else:
				# WARNING animations for 0 hp change may be removed in the future.
				damage = 0 # we still want to display that a card got attacked, even if they didn't lose any health because of it.
		elif _target is int: # if the target is a player,
			pass
			
		return {
			"target": _target,
			"cause": attacker.serialize(), # TODO save runtime by passing this in or adding this in in another stage/function
			"type": "Attack",
			"directAttack": true,
			"statChange": {
				# account for attack bonuses AND the defense bonuses of the target
				"health": -damage,
			}
		}
	else:
		return {}

## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
func serialize() -> Dictionary:
	var output: Dictionary = {
		"subtype": "AttackDirect",
		"content": {
			"base_damage": base_damage,
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
	
	if _object.content.has("base_damage") and _object.content.base_damage != base_damage:
		base_damage = _object.content.base_damage
		# TODO emit signal
	
	super.deserialize(_object)
	
