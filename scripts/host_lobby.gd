extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	# connect signals to broadcast messages
	Lobby.server_up.connect(broadcastMessage) # server creation
	Lobby.player_info_changed.connect(playerInfoChanged) # opponent connection
	
	# create and join the server
	Lobby.createServer($"Player Name".text)
	
	# connect signal to detect when the opponent has joined the lobby.
	# DO NOT connect this signal before creating the server, as calling createServer() connects the current player to the server and emits the signal
	Lobby.player_connected.connect(_opponent_connected)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



## Called when the opponent joins the lobby. The game is now ready to start.
func _opponent_connected(id):
	# enable the button that allows the game to be started
	$StartGameButton.disabled = false
	$StartGameButton.text = "START GAME"

## Called when someone's info changes
func playerInfoChanged(id: int) -> void:
	print("ID: ", id)
	if (id == 1):
		return # no need to update information if the user's information has changed (that would be useless :P)
	else: # another player's information has changed!
		# update opponent's name
		print("update player name", id, ", ", Lobby.players[id])
		$"Icon_Stickman/YOU".text = Lobby.players[id].name

## Called when the user requests the game to be started.
func _on_start_game_button_button_up():
	# tell the opponent to load the level scene
	Lobby.startGame.rpc()
	
	# load the level scene yourself
	Lobby.startGame()

func broadcastMessage(message: String):
	$"Status Message".text = message
	$"Status Message/Timer".start()

## Status messages only appear for 5 seconds before being removed. This function enforces this policy once the 5 second timeout has passed.
func _on_status_message_timeout():
	$"Status Message".text = ""
