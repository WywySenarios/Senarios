extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_button_down(type):
	get_tree().change_scene_to_file("res://scenes/" + type + "/" + type + ".tscn")


func _on_host_game_button_button_down():
	get_tree().change_scene_to_file("res://scenes/host_lobby.tscn")


func _on_join_game_button_button_down():
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
