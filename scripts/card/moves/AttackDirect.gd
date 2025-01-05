class_name AttackDirect extends Move

@export var base_damage : int = 0

func execute(target: Card, attacker: Card):
	if (attacker.aggressive):
		target.hurt((base_damage * attacker.attackMultiplier) + attacker.attackBonus)

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
	output.merge(super.serialize(), false)
	return output

## TODO testing, signals
## Deserialize the dictionary and inject its data into the card this was called on.
## Calls updates only when there is a change in the values or references
## @experimental
func deserialize(_object: Dictionary) -> void:
	# ensure validity (this could be removed given that the child class usually ensures validity as well)
	if not _object.has("type") or _object.type != "Move" or _object.has("content"):
		return
	
	if _object.content.has("base_damage") and _object.content.base_damage != base_damage:
		base_damage = _object.content.base_damage
		# TODO emit signal
	
