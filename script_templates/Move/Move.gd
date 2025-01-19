#class_name TODO
extends Move

# TODO add in attributes

func getType() -> String:
	return "Move" # TODO

func execute(_target: Variant, attacker: Card) -> Dictionary:
	if (attacker is Entity and attacker.aggressive) or (attacker is Special):
		pass
	return {}

## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
func serialize() -> Dictionary:
	var output: Dictionary = {
		"subtype": "AttackDirect",
		"content": {
			# TODO add in attributes
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
	#if _object.content.has("base_damage") and _object.content.base_damage != base_damage:
		#base_damage = _object.content.base_damage
		# TODO emit signal
	
	super.deserialize(_object)
	
