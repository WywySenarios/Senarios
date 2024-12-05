extends Node2D

## Is the player currently dragging any object?
var is_dragging = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## Setter for [member is_dragging]
func startDragging():
	get_tree().call_group("droppable", "setVisibility", true)
	is_dragging = true

## Setter for [member is_dragging]
func stopDragging():
	get_tree().call_group("droppable", "setVisibility", false)
	is_dragging = false
