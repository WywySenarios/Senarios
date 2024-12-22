extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	# connect signals to broadcast messages
	multiplayer.connection_failed.connect(failed_to_join) # failed connection
	Lobby.player_info_changed.connect(playerInfoChanged) # server host's name?


# Called every frame. 'delta' is the elaspsed time since the previous frame.
func _process(delta):
	pass


## Attempts to connect to the host with the IP address specified in the respective text box (as inputted by the user)
func _on_join_button_pressed() -> void:
	# try to join the lobby. If the attempt fails, tell the user that they couldn't connect.
	if Lobby.joinGame($"Player Name".text, $IPAddressInput.text) != null:
		failed_to_join()
	else: # Upon successful connection,
		# send player's info
		pass
		#Lobby.sendPlayerName($"Player Name".text, Lobby.peer.get_unique_id())
	

func playerInfoChanged(id: int) -> void:
	if id == 1: # if the host's information changed
		# change name to match the host's name
		# this is NOT confirmed to work
		$"Icon_Wywy/YOU".text = Lobby.players[id].name

## This function broadcasts a message to the user via the $"Status Message" label node.
func broadcastMessage(message: String) -> void:
	$"Status Message".text = message
	
	# start the 5 second delay until the status message is destroyed.
	$"Status Message/Timer".start()


## Called when the client's attempt to connect to the server has failed.
func failed_to_join() -> void:
	broadcastMessage("Failed to connect to the server. Ensure that the IP address you typed in is valid, and the IP address is currently hosting a game.")
	


## Status messages only appear for 5 seconds before being removed. This function enforces this policy once the 5 second timeout has passed.
func _on_status_message_timeout() -> void:
	$"Status Message".text = ""
