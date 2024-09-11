extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	Global.reprocess_screen_size() # make sure that everyone is updated on the latest screen_size

func reprocess_screen_size():
	$"Control/GUI Band".set_anchors_preset(Control.PRESET_CENTER)
	$"Control/GUI Band".grow_horizontal = Control.GROW_DIRECTION_BOTH
	$"Control/GUI Band".grow_vertical = Control.GROW_DIRECTION_BOTH
	
	$"Control/GUI Band".size = Global.screen_size * 0.5
	# CONTROL.PRESET_MODE_KEEP_SIZE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
