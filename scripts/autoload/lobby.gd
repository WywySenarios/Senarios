extends Node

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id)
signal player_disconnected(peer_id)
signal server_disconnected
signal server_up ## emitted when there is an attempt to initialize the server. Returns a string relevant to the outcome of the server initiailization attempt.
signal player_info_changed(peer_id)

var peer
## Stores the ID of the client
var myID: int = -1
## Stores the name of the client
var myName: String
## stores the current player
var me: Player = null

const PORT: int = 5323
const DEFAULT_SERVER_IP: String = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS: int = 2
const DEFAULT_PLAYER_NAME: String = "???"


# Data section
## This will contain player info for every player, with the keys being each player's unique IDs.
## Each key should be the player's id (integer). Each value should be a player object.
## This dictionary is only populated with all the correct content on the server. Clients should have a limited access to correct information.
## @experimental
var players: Dictionary = {}
## This will contain the indexes of the starting cards that the player wishes to have.
## Each key should be the player's id (integer). Each value should be an array with the indexes of their deck that they want.
## The array should be like this: [0 or 4, 1 or 5, 2 or 6, 3 or 7].
## Clients should NOT have access to this information
var playersStartingHandIndexes: Dictionary = {}

## This contains all the ids of the players who have successfully chosen their starting hand.
var playersReady = []

## Stores the current stage of the game:
## {
##	name: "Lobby", Card Draw", "Turn"; String
##	player: 1 # the respective player. If there is no player related to the game state, this should have a value of -1, NaN, null, etc.; Integer
## }
var gameState: Dictionary = {
	"name": "Lobby",
	"player": -1
}

## An array that contains EVERY player's ID.
var playerIDs: Array[int]




# signals to be used during the card draw phase:
signal newCard(index: int, card: Card)






# signals for use during gameplay:
## Called when the inventory size of a player has been updated.
## ID refers to the player whose inventory has been updated.
## It is intended for the client to play an animation when this signal is called.
signal inventoryUpdated(id: int, oldInventorySize: int)
## Called when the deck size of a player has been updated.
## ID refers to the player whose deck has been updated.
## It is intended for the client to play an animation when this signal is called.
signal deckUpdated(id: int, oldDeckSize: int)

signal moveUpdated(index: Array[int], move: Move)
signal abilityUpdated(index: Array[int], ability: Ability)
## will be split into seperate signals later.
## @deprecated
signal cardStatUpdated(index: Array[int], statName: String, newMagnitude: int)
signal playerHealthUpdated(id: int, oldHealth: int)
signal playerEnergyUpdated(id: int, oldEnergy: int)

# Gameplay variables:
var round: int = 0

func _ready():
	multiplayer.peer_connected.connect(peerConnected)
	multiplayer.peer_disconnected.connect(peerDisconnected)
	multiplayer.connected_to_server.connect(connectedToServer)
	multiplayer.connection_failed.connect(connectionFailed)
	#multiplayer.server_disconnected.connect(_on_server_disconnected)

func peerConnected(id: int):
	print("Peer connected: ", id)
	# add the player's ID to the registry
	playerIDs.append(id)
	playerIDs.sort()
	
	player_connected.emit(id)

func peerDisconnected(id: int):
	print("Player disconnected: ", id)
	# remove the player's ID from the registry
	playerIDs.pop_at(playerIDs.bsearch(id))	
	
	player_disconnected.emit(id)
	
## Called when a [peer who is not the host] has joined the server.
func connectedToServer():
	print("connected to server!")
	## tell the HOST (id = 1) that you just connected, and drop your name, too!
	sendPlayerName.rpc_id(1, myName, multiplayer.get_unique_id())
	
func connectionFailed():
	print("Couldn't connect.")

## ONLY to be called when a player is joining through the lobby
@rpc("any_peer")
func sendPlayerName(name: String, id: int, signalToFire: Signal = player_info_changed):
	if !players.has(id):
		players[id] = Player.new()
		players[id].name = name
		#players[id].energy = 0
		#players[id]["isTheirTurn"] = false
		players[id].id = id
		#players[id].inventory = []
		players[id].playerNumber = len(players)
		# TODO change from hard coded deck
		players[id].deck = load("res://data/decks/Default Stickman.tres")
	
	if id == myID: # if this is my own information,
		me = players[id]
	
	if multiplayer.is_server():
		for i in players:
			sendPlayerName.rpc(players[i].name, i)
	signalToFire.emit(id)
	#print("done sending player info", id, ", ", name)
	

@rpc("any_peer")
func sendFullPlayerInformation(player: Player, id, signalToFire: Signal = player_info_changed):
	players[id] = player
	
	if id == myID: # if this is my own information,
		me = players[id]
	
	signalToFire.emit(id)



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
	
	myName = "Host"
	sendPlayerName(myName, 1)
	# additionally, the Host always has the first move.
	players[1].isTheirTurn = true
	
	# remember your ID!
	myID = 1
	
	player_info_changed.emit(1)
	
	# broadcast that the server has successfully been started.
	server_up.emit("The server has been successfullly created.")

## This function is called to join the server on the IP address specified in serverIP
## Called ONLY clientside
func joinGame(playerName: String, serverIP = ""):
	# ensure that the player name is not empty (that would be confusing to see in the UIs)
	if playerName.is_empty(): playerName = DEFAULT_PLAYER_NAME
	
	# register your new name! :D
	myName = playerName
	
	peer = ENetMultiplayerPeer.new()
	if (serverIP.is_empty()): # detect if the player wants to connect to the default server ip
		serverIP = DEFAULT_SERVER_IP
	
	# @todo please change from DEFAULT_SERVER_IP to the actual IP the client wants to join
	var error = peer.create_client(serverIP, PORT)
	if error != OK: # failed connection
		return error
	else:
		
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)
		
		# remember your own ID!
		myID = peer.get_unique_id()

## starts the game
@rpc("authority", "reliable", "call_local")
func startGame():
	# load the correct scene
	get_tree().change_scene_to_file("res://scenes/level.tscn")

	
	if multiplayer.is_server():
		# the server is responsible for telling the users which starting hands they have received
		for i in players:
			# shuffle everyones' decks without notifying them
			players[i].deck.shuffle()
			
			# tell the player which starting hand they have received
			var cardsToPassIn: Array[Card] = [players[i].deck.content[0], players[i].deck.content[1], players[i].deck.content[2], players[i].deck.content[3]]
			startingHand.rpc_id(i, cardsToPassIn)
	







# This function sends the player info of the host to the other client.


## Reshuffles the deck of the player with the ID specified.
## ID referes to the player whose deck is being shuffled.
## @experimental
func shuffleDeck(id: int):
	# actually shuffles the deck
	players[id].deck.shuffle()
	
	#changeDeckLength.rpc(players[id], id) # broadcast deck length changes

## Called when the deck length of a player has changed.
## ID refers to the player whose deck has changed.
## @experimental
# TODO specify RPC paramters to ensure security
@rpc("authority", "reliable")
func changeDeckLength(deckLength: int, id: int):
	# TODO discover whether or not the signal should be emitted before (to preserve the correct old value) or after (because that's what's intuitive)
	deckUpdated.emit(id, deckLength)
	
	players[id].deckLength = deckLength


## Called by the server to notify the client about their starting hand.
@rpc("authority", "call_local", "reliable")
func startingHand(cards: Array[Card]):
	for i in range(len(cards)):
		print("emits", i, cards[i])
		newCard.emit(i, cards[i])

## Called when the player wants to redraw a card during the card selection phase.
# TODO fix up RPC paramters
@rpc("any_peer", "reliable")
func rerollWish(index: int, id: int):
	# check for valid input
	if 0 <= index and index <= 3: # IDK why I need the "and" keyword here XD
		if multiplayer.is_server(): # ensure only the server responds
			playersStartingHandIndexes[id][index] += 4
			approvedRerollWish.rpc_id(id, index + 4, players[id].deck[index + 4])
	else:
		return
	# contact ONLY the player who has drawn the card that they have received a new card.
	#sendFullPlayerInformation.rpc.id(id, players[id], id)

## Called on by the server to notify the respective user that their reroll has been approved.
## The only (intended) thing this does is emit a signal to notify the level scene to update the UI.
@rpc("authority", "reliable")
func approvedRerollWish(index: int, card: Card):
	newCard.emit(index, card)



## Called when the game stage is to change.
## Can be called by anyone, but only takes effect if the correct person calls it.
## Additionally, calling this during the card selection phase marks that the player who called it is ready.
## To call this function, call the HOST using rpc_id.
# TODO fix up RPC parameters
@rpc("any_peer", "reliable")
func changeGameState(id: int):
	# if the current state of the game is ...,
	if gameState.name == "Card Draw":
		# TODO implement card selection phase code
		# give the players their cards
		pass
	# TODO decide if this is the right client to call
	# TODO implement turn code
	# TODO call this after lobby creation
	# TODO ensure that the clients have been notified
	pass

## Called when all players' turns have expired and a new round start. Should ONLY be called by the host.
func serverNextRound():
	round += 1
	var signalsToFire = []

	for id in players:
		# Players start out with one energy on turn one. On turn two, they get two energy, and this continues until the 10th turn, as the starting energy caps out at ten (without any specials, generators, etc.)
		# the equals sign is there because the round number updates before the energyRate updates.
		if round <= 10:
			players[id].energyRate += 1
		
		# give players more energy
		var oldEnergy = players[id].energy
		players[id].energy = players[id].energyRate
		signalsToFire.append(emit_signal.bind("playerEnergyUpdated", id, oldEnergy)) # prepare to broadcast change

		# give players more cards
		var oldInventorySize = players[id].inventory.size()
		players[id]
		signalsToFire.append(emit_signal.bind("inventoryUpdated", id, oldInventorySize)) # prepare to broadcast change
		

## Broadcasts new information relevant to the next round.
# TODO fix up RPC parameters
@rpc("authority", "reliable")
func nextRound(newRoundNumber: int, newPlayerData: Dictionary, signalsToFire: Array):
	



	# TODO give players more energy
	# TODO give players more cards
	# TODO ensure that the clients have been notified
	pass

# TODO fix up RPC parameters
@rpc
func placeCard():
	# TODO ensure the right person has placed the card at the right time
	# TODO ensure that the clients have been notified
	pass

# TODO fix up RPC parameters
func move():
	# TODO ensure the right person has called the function at the right time
	# TODO process move logic
	# TODO ensure updates are pushed
	pass

## called when a client requests to change the active move of a card active on the field.
# TODO fix up RPC parameters
@rpc
func changeActiveMove():
	# TODO ensure the right person has called the function at the right time
	# TODO ensure updates are pushed
	pass


## Called when the server wants to hand over a card into the client's inventory.
## EVERY person will be notified that the card has been drawn. However, only the relevant player will know exactly what card has been drawn.
## This function has a special behaviour when the player's inventory is already full TODO @experimental 
# TODO fix up RPC paramters
# TODO use rpc_id to call this function properly
@rpc("authority", "call_local", "reliable")
func handOverCard(card: Card):
	pass
