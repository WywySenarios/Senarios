extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in $tiles.get_children():
		pass
	
	for i in $Cards.get_children():
		i.placed.connect(_on_card_placement)
		#print("connected!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_card_placement(card):
	print("Someone played a card!")
	print(card)
