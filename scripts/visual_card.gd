extends Node2D

@export var card : Card

# Called when the node enters the scene tree for the first time.
func _ready():
	$Image.texture = card.image


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
