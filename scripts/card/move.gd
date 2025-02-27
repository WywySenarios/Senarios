class_name Move extends Resource
## Generic Move class. Is not intended to be used directly. Please use child classes like [AttackDirect] and [MoveLane]

@export var name : String = "N/A"
@export var tooltip : String = ""
@export var quick_tooltip : String = ""

func _init(arg: Variant = null):
	match typeof(arg):
		TYPE_DICTIONARY:
			Lobby.deserialize(arg)

func getType() -> String:
	return "Move"

## Returns a Dictionary containing all the information that this Move wants to change.
func execute(target: Variant, parent: Card) -> Variant:
	return {}

## Transform this Move's data into a Dictionary.
## Does not modify the Move's contents.
func serialize() -> Dictionary:
	return {
		"type": "Move",
		"content": {
			"name": name,
			"tooltip": tooltip,
			"quick_tooltip": quick_tooltip,
		}
	}

## Deserialize the dictionary and inject its data into the Move this was called on.
## Calls updates only when there is a change in the values or references
func deserialize(_object: Dictionary) -> void:
	# ensure validity (this could be removed given that the child class usually ensures validity as well)
	if not _object.has("type") or _object.type != "Move" or not _object.has("content"):
		return
	
	if _object.content.has("tooltip") and _object.content.tooltip != tooltip:
		tooltip = _object.content.tooltip
		# Do not emit signal (flavor text)
		
	if _object.content.has("quick_tooltip") and _object.content.quick_tooltip != quick_tooltip:
		quick_tooltip = _object.content.quick_tooltip
		# Do not emit signal (flavor text)
