extends Node
#region Server Constants
const PORT: int = 5323
const DEFAULT_SERVER_IP: String = "127.0.0.1" # IPv4 localhost
const MIN_CONNECTIONS: int = 2
const MAX_CONNECTIONS: int = 2
const DEFAULT_PLAYER_NAME: String = "???"
#endregion

#region Generic Server Signals
signal player_connected(peer_id)
signal player_disconnected(peer_id)
signal server_disconnected
signal server_up ## emitted when there is an attempt to initialize the server. Returns a string relevant to the outcome of the server initiailization attempt.
signal player_info_changed(peer_id)
#endregion

#region Player Information
## Temporary varaible. Not used after the lobby phase ends.
var peer
## Stores the ID of the client
var myID: int = -1
## Stores the name of the client
var myName: String
## stores the current player
var me: Player = null
## Stores the reference to the level scene
var levelScene: Control
#endregion

#region Server Data
# ----------------------------------------
# Server Data: INFO informs important information relating to both the server and the game
## This will contain player info for every player, with the keys being each player's unique IDs.
## Each key should be the player's id (integer). Each value should be a player object.
## This dictionary is only populated with all the correct content on the server. Clients should have a limited access to correct information.
## @experimental
var players: Dictionary = {}

## This contains all the ids of the players who have successfully chosen their starting hand.
var playersReady = []

## Stores all the card selection indexes. Key is the player ID, value is an array with the deck indexes selected.
var playerCardSelectionIndexes: Dictionary = {}

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

var gameRound: int = 0
#endregion

#region Card Draw Phase Signals
# ----------------------------------------
# signals to be used during the card draw phase:
## This signal emits with the index of the deck and a string with the card ID
signal newCard(index: int, card: String)
#endregion

#region Gameplay Event Signals
## Called when a player has gained a new card.
## ID refers to the player whose inventory has been updated.
## It is intended for the client to play an animation when this signal is called.
## The card parameter may be a single card or an array of cards.
signal inventorySizeIncreased(id: int, oldInventorySize: int, card)
## Called when the deck size of a player has been updated.
## ID refers to the player whose deck has been updated.
## It is intended for the client to play an animation when this signal is called.
signal deckUpdated(id: int, oldDeckSize: int)

## This signal emits with the index related to the grid and the move ID
signal moveUpdated(index: Array[int], move: String)
## This signal emits the index related to the grid and the ability ID
signal abilityUpdated(index: Array[int], ability: String)
## will be split into seperate signals later.
## @deprecated
signal cardStatUpdated(index: Array[int], statName: String, newMagnitude: int)
signal playerHealthUpdated(id: int, oldHealth: int)
signal playerEnergyUpdated(id: int, oldEnergy: int)
signal gameStateChange(oldGameStateName: String, oldGameStatePlayer: int)
#endregion

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

#region Lobby & Pre-game Functions
## ONLY to be called when a player is joining through the lobby
@rpc("any_peer")
func sendPlayerName(playerName: String, id: int, signalToFire: Signal = player_info_changed):
	if !players.has(id):
		players[id] = Player.new()
		players[id].name = playerName
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

## Pre-cardDraw stage functionality
func preGame():	
	if multiplayer.is_server():
		# the server is responsible for telling the users which starting hands they have received
		for i in players:
			# shuffle everyones' decks without notifying them
			players[i].deck.shuffle()
			
			# tell the player which starting hand they have received
			var cardsToPassIn: Array[String] = [players[i].deck.content[0], players[i].deck.content[1], players[i].deck.content[2], players[i].deck.content[3]]
			startingHand.rpc_id(i, cardsToPassIn)
			
			# store which deck indexes the players have chosen thusfar
			playerCardSelectionIndexes[i] = [0, 1, 2, 3]
		
		# start the card selection game stage
		approveGameStateChange.rpc("Card Draw", -1)
#endregion


## Reshuffles the deck of the player with the ID specified.
## ID refers to the player whose deck is being shuffled.
## This function notifies the player that their deck has been shuffled (not implemented yet)
## @experimental
func shuffleDeck(id: int):
	# actually shuffles the deck
	players[id].deck.content.shuffle()
	
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
## The argument is an array of strings relating to the cards' resource path relative to the resource folder.
@rpc("authority", "call_local", "reliable")
func startingHand(cards: Array[String]):
	for i in range(len(cards)):
		newCard.emit(i, cards[i])

## Called when the player wants to redraw a card during the card selection phase.
# TODO fix up RPC paramters
@rpc("any_peer", "reliable")
func rerollWish(index: int, id: int):
	# check for valid input
	if 0 <= index and index <= 3: # IDK why I need the "and" keyword here XD
		if multiplayer.is_server(): # ensure only the server responds
			playerCardSelectionIndexes[id][index] += 4 # update card selection index
			approvedRerollWish.rpc_id(id, index + 4, players[id].deck.content[index + 4]) # approve request
	else:
		return
	# contact ONLY the player who has drawn the card that they have received a new card.
	#sendFullPlayerInformation.rpc.id(id, players[id], id)

## Called on by the server to notify the respective user that their reroll has been approved.
## The only (intended) thing this does is emit a signal to notify the level scene to update the UI.
@rpc("authority", "reliable")
func approvedRerollWish(index: int, card: String):
	newCard.emit(index, card)






## Called when the game stage is to change.
## Can be called by anyone, but only takes effect if the correct person calls it.
## Additionally, calling this during the card selection phase marks that the player who called it is ready.
@rpc("any_peer", "reliable", "call_local")
func changeGameState(id: int):
	if multiplayer.is_server():
		# if the current state of the game is ...,
		if gameState.name == "Card Draw":
			if playersReady.find(id) != -1: # if the player already readied up,
				return # do NOT do anything.
			
			
			# give the player their cards
			for a in playerCardSelectionIndexes[id]:
				drawCard(id, a) # players draw the respective index of their deck
				
			# shuffle deck because the players have already peaked at the first couple of cards
			shuffleDeck(id)
			
			# mark the player as ready for the next round
			playersReady.append(id)
			
			# see if everyone is ready or not
			if len(playersReady) == players.size():
				approveGameStateChange.rpc("Turn", 1)
	# TODO decide if this is the right client to call
	# TODO implement turn code
	# TODO call this after lobby creation
	# TODO ensure that the clients have been notified

## Called when the server wants the game state to change.
## To get the game state to change, call "changeGameState" on the server using rpc_id
@rpc("authority", "reliable", "call_local")
func approveGameStateChange(name: String, player: int):
	var oldName: String = gameState.name
	var oldPlayer: int = gameState.player
	print("Game state change approved: ", name, ", ", player)
	gameState = {
		"name": name,
		"player": player
	}
	
	gameStateChange.emit(oldName, oldPlayer)

## Called when all players' turns have expired and a new round start. Should ONLY be called by the host.
func serverNextRound():
	gameRound += 1
	var signalsToFire = []

	for id in players:
		# Players start out with one energy on turn one. On turn two, they get two energy, and this continues until the 10th turn, as the starting energy caps out at ten (without any specials, generators, etc.)
		# the equals sign is there because the round number updates before the energyRate updates.
		if gameRound <= 10:
			players[id].energyRate += 1
		
		# give players more energy
		var oldEnergy = players[id].energy
		players[id].energy = players[id].energyRate
		signalsToFire.append(emit_signal.bind("playerEnergyUpdated", id, oldEnergy)) # prepare to broadcast change

		# give players more cards
		var oldInventorySize = players[id].inventory.size()
		
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
	
## The function that handles a player drawing a card from their deck.
@rpc("authority", "call_local", "reliable")
func drawCard(target: int, deckIndex: int):
	handOverCard(target, players[target].deck.content[deckIndex])

## The function that gets called when someone is to receive a card (not necessarily a draw card function)
## EVERY person will be notified that the card has been drawn. However, only the relevant player will know exactly what card has been drawn.
## This function has a special behaviour when the player's inventory is already full TODO @experimental
## The target parameter refers to the player (ID) who has received the card.
@rpc("authority", "call_local", "reliable")
func handOverCard(target: int, _card: String):
	var card: Card = load("res://resources/" + _card + ".tres")
	var oldInventorySize: int = len(players[target].inventory)
	
	# store the card in the right player
	players[target].inventory.append(card)
	
	# notify other scenes that a player's inventory has updated
	inventorySizeIncreased.emit(target, oldInventorySize, card)
	
	
	if multiplayer.is_server():
		# broadcast a potentially censored message to everyone
		for i in players:
			if i == 1: # do NOT tell the host about it (this would cause infinite recursion)
				pass
			elif i == target: # tell the recipient about the contents of the actual card
				handOverCard.rpc_id(i, target, _card)
			else: # censor the card contents
				handOverCard.rpc_id(i, target, "empty")


## The function that gets called when someone is to receive multiple cards at once (not necessarily a draw card function)
## EVERY person will be notified that the card has been drawn. However, only the relevant player will know exactly what card has been drawn.
## This function has a special behaviour when the player's inventory is already full TODO @experimental
## The target parameter refers to the player (ID) who has received the card.
@rpc("authority", "call_local", "reliable")
func handOverCards(target:int, _cards: Array[String]):
	var card: Card
	var oldInventorySize: int = len(players[target].inventory)
	var censoredCards = []
	
	for i in _cards:
		card = load("res://resources/" + i + ".tres")
		censoredCards.append("empty")
		
		# store the card in the right player
		players[target].inventory.append(card)
	
	# notify other scenes that a player's inventory has updated
	inventorySizeIncreased.emit(target, oldInventorySize, _cards)
	
	
	if multiplayer.is_server():
		
		# broadcast a potentially censored message to everyone
		for i in players:
			if i == 1: # do NOT tell the host about it (this would cause infinite recursion)
				pass
			elif i == target: # tell the recipient about the contents of the actual card
				handOverCards.rpc_id(i, target, _cards)
			else: # censor the card contents
				handOverCards.rpc_id(i, target, censoredCards)
