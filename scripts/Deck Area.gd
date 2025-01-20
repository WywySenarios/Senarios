extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	modulate = Color(modulate, 0.5)

func setVisibility(visibility: bool):
	visible = visibility
