extends Resource
class_name Card

# TODO stat change signals (do NOT contact player, just directly route those signals to the card scenes for them to deal with animations).

@export var name : String = "N/A"
## The cardID directly relates to the path where the card should be stored.
## It is the file name without the file extension.
@export var cardID: String = ""
@export var cardType : String = ""
@export_range(1, 6) var generation : int
@export var cost : float = 0
@export var type : Array[String]
@export var image : CompressedTexture2D
@export var move : Move = Move.new()

func _init(arg: Variant = null):
	match typeof(arg):
		TYPE_DICTIONARY:
			deserialize(arg)

#region Serialization
## TODO test this function
## Transform this card's data into a Dictionary.
## Does not modify the card's contents.
## @experimental
func serialize() -> Dictionary:
	return {
		"type": "Card",
		"content": {
			"name": name,
			"cardID": cardID,
			"cardType": cardType,
			"generation": generation,
			"cost": cost,
			"type": type.duplicate() as Array[String],
			"move": move.serialize(),
			## Do NOT return the image because it is a compressed texture. The deserialization should be able to take care of textures.
		}
	}

## TODO testing, signals
## Deserialize the dictionary and inject its data into the card this was called on.
## Calls updates only when there is a change in the values or references
## @experimental
func deserialize(_object: Dictionary) -> void:
	# ensure validity
	if not _object.has("type") or _object.type != "Card" or not _object.has("content"):
		print_debug("A Card was given an invalid dictionary to deserialize.")
		return
	
	if _object.content.has("name") and _object.content.name != name:
		name = _object.content.name
		# TODO emit signal
	
	if _object.content.has("cardID") and _object.content.cardID != cardID:
		cardID = _object.content.cardID
		# TODO emit signal
		
		# add image
		image = load("res://assets/cards/card_images/cardImage-" + cardID + ".png")
	
	if _object.content.has("cardType") and _object.content.cardType != cardType:
		cardType = _object.content.cardType
		# TODO emit signal
	
	if _object.content.has("generation") and _object.content.generation != generation:
		generation = _object.content.generation
		# TODO emit signal
	
	if _object.content.has("cost") and _object.content.cost != cost:
		cost = _object.content.cost
		# TODO emit signal
	
	if _object.content.has("type") and _object.content.type != type:
		type = _object.content.type
		# TODO emit signal
	
	# WARNING TODO fix checking if the data is the same or not. I KNOW it doesn't work properly right now.
	if _object.content.has("move"): #and _object.content.move != move:
		move = Lobby.deserialize(_object.content.move)
		# TODO emit signal
#endregion
