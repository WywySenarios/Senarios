class_name GenerateEnergy extends Move

@export var energy: int = 1

func getType() -> String:
	return "Conjure" # TODO find a better name

func execute(_target: Variant, attacker: Card) -> Dictionary:
	return {
		"target": _target,
		"cause": null, # TODO fix
		"type": "GenerateEnergy",
		"directAttack": false, # not relevant
		"statChange": {
			"energy": energy,
		}
	}

## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
func serialize() -> Dictionary:
	var output: Dictionary = {
		"subtype": "GenerateEnergy",
		"content": {
			"energy": energy,
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
	if _object.content.has("energy") and _object.content.energy != energy:
		energy = _object.content.energy
		# TODO emit signal
	
	super.deserialize(_object)
	
