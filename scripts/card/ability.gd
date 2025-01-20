class_name Ability extends Resource
## Class for Abilities.

@export var name : String = "N/A"
@export var tooltip : String = ""
@export var quick_tooltip : String = ""
## Flags that will cause this ability to trigger.
@export var flags: Array[String] = []
## The move that executes when this ability triggers.
@export var move: Move = Move.new()
## Whether or not this ability requires a prompt.
## If so, specify what the criteria of the prompt is.
## If not, leave as an empty dictionary.
## Please refer to [Server] for what a valid prompt is.
@export var prompt: Dictionary = {}

func _init(arg: Variant = null):
	match typeof(arg):
		TYPE_DICTIONARY:
			deserialize(arg)

## Returns a Dictionary containing all the information that this Ability wants to change.
func execute(target: Variant, parent: Card) -> Variant:
	return move.execute(target, parent)

## Transform this Ability's data into a Dictionary.
## Does not modify the Ability's contents.
func serialize() -> Dictionary:
	var output: Dictionary =  {
		"type": "Ability",
		"content": {
			"name": name,
			"tooltip": tooltip,
			"quick_tooltip": quick_tooltip,
			"flags": flags,
		}
	}
	
	if move != null:
		output.content["move"] = move.serialize()
	
	return output

## Deserialize the dictionary and inject its data into the Ability this was called on.
## Calls updates only when there is a change in the values or references
func deserialize(_object: Dictionary) -> void:
	# ensure validity (this could be removed given that the child class usually ensures validity as well)
	if not _object.has("type") or _object.type != "Ability" or not _object.has("content"):
		return
	
	if _object.content.has("tooltip") and _object.content.tooltip != tooltip:
		tooltip = _object.content.tooltip
		# Do not emit signal (flavor text)
		
	if _object.content.has("quick_tooltip") and _object.content.quick_tooltip != quick_tooltip:
		quick_tooltip = _object.content.quick_tooltip
		# Do not emit signal (flavor text)
	
	if _object.content.has("flags") and _object.content.flags != flags:
		flags = _object.content.flags
		# TODO emit signal
	
	if _object.content.has("move"): # do not bother checking for equality due to runtime
		move = Lobby.deserialize(_object.content.move)
	
	if _object.content.has("prompt"):
		prompt = _object.content.prompt
