class_name BonusAttack extends Move

# add in attributes

func getType() -> String:
	return "BonusAttack"

func execute(_target: Variant, attacker: Card) -> Dictionary:
	if _target is Array[int]:
		var cardInQuestion = Lobby.activeCards[_target[0]][_target[1]]
		if cardInQuestion != null and cardInQuestion.card != null and cardInQuestion.card.move != null: # CRITICAL verify if "aggressive" Entity attribute is important
			return cardInQuestion.execute(Lobby.findTarget(cardInQuestion.card.move, _target[0], _target[1]))
		else:
			return {}
	else:
		return {}

## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
func serialize() -> Dictionary:
	var output: Dictionary = {
		"subtype": "BonusAttack",
		"content": {
			
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
	
