class_name Conjure extends Move
## Conjure does one of these things (in order):
##	* Conjures a specifc card, as specified by [member cardToConjure].
##	* Conjures a card from any of the [member conjureType]s. DOES NOT WORK
##	* Conjures any card in the game that relates to the player (e.g. Wywys get wywy cards, Stickmen get Stickmen cards). DOES NOT WORK
## Conjure follows the first behaviour found as specified above. (e.g. [member conjureType]'s value doesn't matter if [member cardToConjure] is specified).
## Conjure does NOT cause card draw from the deck, and therefore does NOT change the deck length.

## This contains the exact card this Move wants to conjure when executed.
@export var cardToConjure: String = ""
## @experimental DOES NOT WORK
@export var conjureType: Array[String] = [""]
#@export var cardModifications: Dictionary = {}

## @deprecated
func getType() -> String:
	return "Conjure"

## Conjures a random card based on [member cardToConjure] and [member conjureType].
func execute(_target: Variant, attacker: Card) -> Dictionary:
	var output: Dictionary
	
	# if we want to conjure a very specific card,
	if cardToConjure:
		output = Global.loadCard(cardToConjure).serialize()
	else:
		# TODO add conjureType & conjureAny behaviour
		output = {}
	
	
	return {
		"target": _target,
		"cause": attacker.serialize(),
		"type": "Conjure",
		"directAttack": false, # does not matter
		"statChange":  {
			"card": output
		}
	}

## TODO test this function
## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
## @experimental
func serialize() -> Dictionary:
	var output: Dictionary = {
		"subtype": "Conjure",
		"content": {
			"cardToConjure": cardToConjure,
			"conjureType": conjureType,
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
	
	if _object.content.has("cardToConjure") and _object.content.cardToConjure != cardToConjure:
		cardToConjure = _object.content.cardToConjure
		# TODO emit signal
	
	if _object.content.has("conjureType") and _object.content.conjureType != conjureType:
		conjureType = _object.content.conjureType
		# TODO emit signal
	
	super.deserialize(_object)
	
