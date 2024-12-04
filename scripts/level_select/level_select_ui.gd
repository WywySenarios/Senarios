extends Control

var missions = []
var mission_page_number = 0
var current_scroll = 0
var num_slides

var screen_size = Vector2.ZERO
var selection_button_size = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	unfocus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print(get_global_mouse_position())
	pass

func reprocess_screen_size(_screen_size):
	screen_size = _screen_size
	size = _screen_size
	selection_button_size.x = screen_size.x / 4.0
	selection_button_size.y = screen_size.y / 6.0
	
	$"Mission/Planet Name".position = screen_size * -0.5
	
	$"Mission/Mission_Rect".size.x = screen_size.x * (1.0/6.0)
	$"Mission/Mission_Rect".position.x = -screen_size.x * 0.5
	$"Mission/Mission_Rect".position.y = -screen_size.y * (0.5 - (1.0 / 6.0))
	
	var a = 0
	for b in $"Mission/Mission_Rect".get_children():
		b.size = selection_button_size
		b.position.y = screen_size.y * a / 6.0
		a += 1
	
	
	# Deck options position & sizing
	$"Deck_Select/Prompt".position.x = screen_size.x * 0.5
	$"Deck_Select/Prompt".position.y = screen_size.y * -0.5
	
	$"Deck_Select/Deck Options".size.x = screen_size.x * (1.0 / 6.0)
	$"Deck_Select/Deck Options".position.x = screen_size.x * (0.5 - (1.0 / 4.0))
	#$"Deck_Select/Deck Options".position.x = 0
	$"Deck_Select/Deck Options".position.y = $"Mission/Mission_Rect".position.y
	
	a = 0
	for b in $"Deck_Select/Deck Options".get_children():
		b.size = selection_button_size
		b.position.y = screen_size.y * a / 6.0
		a += 1
	
	
	#a
	$"Ready Button".position.x = -screen_size.x * 1.0 / 8.0
	$"Ready Button".position.y = -screen_size.y * (0.5 - 1.0 / 6.0)
	$"Ready Button".size.x = screen_size.x / 4.0
	$"Ready Button".size.y = screen_size.y / 6.0

func focus(node):
	$"Mission/Planet Name".text = node.attributes.name
	$"Mission".show()
	
	var mission_buttons = $"Mission/Mission_Rect".get_children()
	for i in range(node.attributes.missions.size()):
		mission_buttons[i].show()
		mission_buttons[i].text = node.attributes.missions[i].name
	
	for i in range(node.attributes.missions.size(), 4):
		mission_buttons[i].hide()
	
	current_scroll = 0
	#@warning_ignore("integer_division")
	num_slides = node.attributes.missions.size() / 4

func unfocus():
	$"Mission".hide()
	$"Ready Button".hide()
	$"Deck_Select".hide()


func _on_ready_button_button_down():
	get_tree().change_scene_to_file("res://scenes/level/command_station.tscn")

func on_button_down(selection_type, selection_number):
	if (selection_type == "mission"):
		$"Deck_Select".show()
	elif (selection_type == "deck"):
		$"Ready Button".show()
		$"Mission/Mission_Rect/Button 1".show()
	#print(selection_type)
	#print(selection_number)
	
