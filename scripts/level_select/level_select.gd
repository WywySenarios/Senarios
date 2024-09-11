extends Node

@export var planet_visibility_zoom_factor : float = 100
@export var satelite_visibility_zoom_factor : float = -7
var active_groups = []

# Called when the node enters the scene tree for the first time.
func _ready():
	# handle mouse events
	pass # Replace with function body.

func _on_physics_camera_zoom(factor):
	var changed_focus_state = false
	#_on_physics_camera_screen_size_update()
	
	if (factor >= satelite_visibility_zoom_factor):
		if not active_groups == ["planets", "satelites"]:
			# view all satelites & planets PLEASE OPTIMIZE LATER
			for i in active_groups:
				if (i != "planets") && i != "satelites":
					hide_group(i)
			
			active_groups = ["planets", "satelites"]
	elif (factor >= planet_visibility_zoom_factor):
		if not active_groups == ["planets"]:
			# view all planets
			for i in active_groups:
				if (i != "planets"):
					hide_group(i)
		
			active_groups = ["planets"]

func hide_group(group_name):
	get_tree().call_group(group_name, "hide")

func show_group(group_name):
	get_tree().call_group(group_name, "is_in_view", $"Physics Camera/Camera".position, Global.screen_size / $"Physics Camera/Camera".zoom.x)

func view_changed(): # function called by $"Physics Camera" when an object has the potential to have moved on or off screen
	for i in active_groups:
		get_tree().call_group(i, "is_in_view", $"Physics Camera/Camera".position, Global.screen_size / $"Physics Camera/Camera".zoom.x)

func focus(node):
	$"Physics Camera".focus(node)
