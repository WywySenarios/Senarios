class_name MoveAll extends Move
## A move where all targets on the board will be affected. As a result, this move cannot directly hurt players. TODO add option to hurt player
## MoveLane can target friendly Entities, hostile Entities, or both. It can also target none, but then there would be no point in having this move.

# TODO add option to hurt player
@export var MoveFriendly: Move = Move.new() # Move to execute on friendly cards in the lane
@export var MoveHostile: Move = Move.new() # Move to execute on hostile cards in the lane
## Criteria for move execution.
## type: "All", "Any", or "None".
## content:
##	match: Matches with the cardID
## NOTE: Cards match all criterion if there are no criteria.
## NOTE: Cards cannot meet any criteria if there are no criteria.
@export var criteria: Dictionary = {
	"type": "All",
	"content": {},
}

func getType() -> String:
	return "MoveAll"

## Attempts to execute the respective Friendly & Hostile moves on every valid target.
## [param _target] is true if this move is played by player 2's card. WARNING hard-coded?
func execute(_target: Variant, attacker: Card) -> Array[Dictionary]:
	if _target == null or not _target is bool:
		return []
	
	var output: Array[Dictionary] = []
	for i in range(Lobby.gridHeight):
		for a in range(Lobby.gridLength):
			if Lobby.activeCards[i][a] != null:
				var moveActive = false
				var matchesAnyCriterion = false
				var matchesAllCriterion = true
				if criteria.content.has("match"):
					if Lobby.activeCards[i][a].card.cardID == criteria.content.match:
						matchesAnyCriterion = true
					else:
						matchesAllCriterion = false
				
				
				match criteria.type:
					"All":
						moveActive = matchesAllCriterion
					"None":
						moveActive = not matchesAllCriterion
					"Any", _:
						moveActive = matchesAnyCriterion
				
				if moveActive:
					# WARNING hard-coded
					@warning_ignore("integer_division")
					var friendly = not i < Lobby.gridHeight / 2 # friendly from the host's perspective?
					# invert friendliness if you are not the host
					if _target:
						friendly = not friendly
					
					if friendly and MoveFriendly != null:
						output.append(MoveFriendly.execute([i, a] as Array[int], attacker))
					elif MoveHostile != null:
						output.append(MoveHostile.execute([i, a] as Array[int], attacker))
						
	
	return output

## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
func serialize() -> Dictionary:
	var output: Dictionary = {
		"subtype": "MoveAll",
		"content": {
			"criteria": {
				"type": criteria.type,
				"content": criteria.content
			}
		},
	}
	
	if MoveFriendly != null:
		output.content.MoveFriendly = MoveFriendly.serialize()
	if MoveHostile != null:
		output.content.MoveHostile = MoveHostile.serialize()
	
	# do NOT override the above data
	var superClassSerializaiton = super.serialize()
	output.merge(superClassSerializaiton, false)
	output.content.merge(superClassSerializaiton.content, false)
	return output

## Deserialize the dictionary and inject its data into the card this was called on.
## Calls updates only when there is a change in the values or references
func deserialize(_object: Dictionary) -> void:
	if _object.content.has("MoveFriendly"): # do not bother checking for equality due to runtime
		MoveFriendly = Lobby.deserialize(_object.content.MoveFriendly)
	
	if _object.content.has("MoveHostile"):
		MoveHostile = Lobby.deserialize(_object.content.MoveHostile)
	
	if _object.content.has("criteria"): #and ((_object.content.criteria.has("type") and _object.content.criteria.type != criteria.type) or (_object.content.criteria.has("content") and _object.content.criteria.content != criteria.content)):
		criteria = _object.content.criteria
		criteria.content = _object.content.criteria.content
		# TODO emit signal
	
	super.deserialize(_object)
	
