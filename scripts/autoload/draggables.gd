extends Node2D

var is_dragging = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func startDragging():
	get_tree().call_group("droppable", "setVisibility", true)
	is_dragging = true

func stopDragging():
	get_tree().call_group("droppable", "setVisibility", false)
	is_dragging = false
