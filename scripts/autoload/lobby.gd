extends Node

# Autoload named Lobby

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id)
signal player_disconnected(peer_id)
signal server_disconnected
signal server_up ## emitted when there is an attempt to initialize the server. Returns a string relevant to the outcome of the server initiailization attempt.

var peer

const PORT = 5323
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 2
const DEFAULT_PLAYER_NAME = "???"

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

var players_loaded = 0


func _ready():
	multiplayer.peer_connected.connect(peerConnected)
	multiplayer.peer_disconnected.connect(peerDisconnected)
	multiplayer.connected_to_server.connect(connectedToServer)
	multiplayer.connection_failed.connect(connectionFailed)
	#multiplayer.server_disconnected.connect(_on_server_disconnected)

func peerConnected(id):
	print("Peer connected: ", id)
	
	player_connected.emit(id)

func peerDisconnected(id):
	print("Player disconnected: ", id)
	
func connectedToServer():
	print("connected to server!")
	
func connectionFailed():
	print("Couldn't connect.")

## This function creates a server and connects the person who is currently trying to host to their own server.
func createServer(playerName: String):
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error != OK:
		server_up.emit("Failed to create server: " + str(error))
		return error
	
	# Select compression algorithm
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	# register new server
	multiplayer.set_multiplayer_peer(peer)
	
	# reigster that you have connected yourself to the server
	player_connected.emit(1)
	
	players[1] = {"name": playerName}
	
	# broadcast that the server has successfully been started.
	server_up.emit("The server has been successfullly created.")

## This function is called to join the server on the IP address specified in serverIP
func joinGame(playerName: String, serverIP = ""):
	# ensure that the player name is not empty (that would be confusing to see in the UIs)
	if playerName.is_empty(): playerName = DEFAULT_PLAYER_NAME
	
	peer = ENetMultiplayerPeer.new()
	if (serverIP.is_empty()): # detect if the player wants to connect to the default server ip
		serverIP = DEFAULT_SERVER_IP
	
	print(serverIP)
	# @todo please change from DEFAULT_SERVER_IP to the actual IP the client wants to join
	var error = peer.create_client(serverIP, PORT)
	if error != OK: # failed connection
		return error
	else:
		
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)


## starts the game
@rpc("authority", "reliable")
func startGame():
	get_tree().change_scene_to_file("res://scenes/level.tscn")







# This function sends the player info of the host to the other client.
