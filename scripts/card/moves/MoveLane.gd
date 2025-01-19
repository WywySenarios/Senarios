class_name MoveLane extends Move
## A move where targets in a certain lane will be affected. As a result, this move cannot directly hurt players.
## MoveLane can target friendly Entities, hostile Entities, or both. It can also target none, but then there would be no point in having this move.

@export var MoveFriendly: Move = Move.new() # Move to execute on friendly cards in the lane
@export var MoveHostile: Move = Move.new() # Move to execute on hostile cards in the lane

func getType() -> String:
	return "MoveLane"

#func getAttackStrength() -> int:

## Executes the child moves on the [friendy grid coordinates, hostile grid coordinates]
## WARNING hard-coded for a single friendly card and a single hostile card.
func execute(_target: Variant, attacker: Card) -> Array[Dictionary]:
	var output = [MoveFriendly.execute(_target[0], attacker), MoveHostile.execute(_target[1], attacker)] as Array[Dictionary]
	print_debug("Move Lane executed", output)
	return output
	
## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
func serialize() -> Dictionary:
	var output: Dictionary = {
		"subtype": "MoveLane",
		"content": {
			"MoveFriendly": MoveFriendly.serialize(),
			"MoveHostile": MoveHostile.serialize(),
		}
	}
	
	# do NOT override the above data
	var superClassSerialization = super.serialize()
	output.merge(superClassSerialization, false)
	output.content.merge(superClassSerialization.content, false)
	return output

## Deserialize the dictionary and inject its data into the card this was called on.
## Calls updates only when there is a change in the values or references
func deserialize(_object: Dictionary) -> void:
	if _object.content.has("MoveFriendly"): # do not bother checking for equality due to runtime
		MoveFriendly = Lobby.deserialize(_object.content.MoveFriendly)
	
	if _object.content.has("MoveHostile"):
		MoveHostile = Lobby.deserialize(_object.content.MoveHostile)
	
	super.deserialize(_object)
