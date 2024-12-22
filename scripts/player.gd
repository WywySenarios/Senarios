extends Resource
class_name Player

## Self-ascribed name. Defaults to ???
@export var name: String = "???"
## Non-optional variable containing the player ID. The default value (no explicitly assigned playerID) is -1.
@export var id : int = -1
@export var energy: int = 0
#@export var statusEffects: 
@export var isTheirTurn: bool = false
## The inventory is an array containing the cards in their inventory.
@export var inventory: Array[Card] = []
