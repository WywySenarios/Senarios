class_name AttackDirect extends Move

## The base damage, before additive and multiplicative attack bonuses (and therefore also before additive and multiplicative defensive bonuses)
## POSITIVITY: A positive integer leads to the target losing health.
@export var base_damage : int = 0

## Deducts health from the target if the attacker is able to attack.
func execute(target: Variant, attacker: Card) -> Dictionary:
	if (attacker.aggressive):
		return {
			"target": target,
			"cause": attacker.serialize(), # TODO save runtime by passing this in or adding this in in another stage/function
			"type": "Attack",
			"directAttack": true,
			"statChange": {
				"health": -((base_damage * attacker.attackMultiplier) + attacker.attackBonus),
			}
		}
	else:
		return {}

## TODO test this function
## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
## @experimental
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

## TODO testing, signals
## Deserialize the dictionary and inject its data into the card this was called on.
## Calls updates only when there is a change in the values or references
## @experimental
func deserialize(_object: Dictionary) -> void:
	# ensure validity (this could be removed given that the child class usually ensures validity as well)
	if not _object.has("type") or _object.type != "Move" or not _object.has("content"):
		return
	
	if _object.content.has("base_damage") and _object.content.base_damage != base_damage:
		base_damage = _object.content.base_damage
		# TODO emit signal
	
	super.deserialize(_object)
	
