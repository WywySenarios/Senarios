extends Node

var screen_size: Vector2

func reprocess_screen_size():
	screen_size = get_viewport().get_visible_rect().size
	get_tree().call_group("Screen Proportion Dependant", "reprocess_screen_size")
