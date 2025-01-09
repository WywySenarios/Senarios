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
@warning_ignore("unused_signal")
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

## Key: player ID
## Value: player number
var playerNumbers: Dictionary = {}

## This contains all the ids of the players who have successfully chosen their starting hand.
var playersReady = []

## Stores all the card selection indexes. Key is the player ID, value is an array with the deck indexes selected.
var playerCardSelectionIndexes: Dictionary = {}

## Stores the current stage of the game:
## {
##	name: "Lobby", Card Draw", "Turn"; String
##	player: 1 # the respective player. If there is no player related to the game state, this should have a value of -1, NaN, null, etc.; Integer
##	content: # any additional paramters and content. Variant.
## }
var gameState: Dictionary = {
	"name": "Lobby",
	"player": -1
}

## An array that contains EVERY player's ID.
## Currently does NOT work whatsoever. Consider using players.keys() instead.
## @deprecated
var playerIDs: Array[int]

var gameRound: int = 0

@warning_ignore("unused_parameter")
var gridTiles: Array[Array]
var activeCards: Array[Array]
## TODO do not hardcode
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
## Targets: Array conotianing the player IDs.
## Params should be well-ordered.
## Was set differentiates whether or not the energy was set (true) or added on and resulted in the final amount (false)
signal playerHealthUpdated(targets: Array[int], oldHealth: Array[int], wasSet: bool)
## Targets: Array containing the player IDs.
## Params should be well-ordered.
## Was set differentiates whether or not the energy was set (true) or added on and resulted in the final amount (false)
signal playerEnergyUpdated(targets: Array[int], oldEnergy: Array[int], wasSet: bool)
signal gameStateChange(oldGameState: Dictionary)

#region Card Status Updates
## @deprecated
signal cardHealthUpdated(location: Array[int], oldHealth)

## Called when a card is summoned.
## NOTE: the Lobby script does not store card data. That is the grid's responsibility.
signal summon(target: Array[int], _card: Card)

## Called when a card attacks another card.
## NOTE: the Lobby script does not directly process what happens here.
signal attack(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool)

## NOTE: source can be null. In that case, directly play the buff animation and don't play any attack particle effects.
signal buff(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool)
signal debuff(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool)

## Called when a card is to be killed.
## NOTE: the Lobby script does not store card data. That is the grid's responsibility.
signal kill(target: Variant)

## Called when an ability is activated.
## NOTE: the Lobby script does not directly process what happens here.
signal ability(target: Variant, ability: Ability)
#endregion
#endregion

#region Game Constants (useful constants to know/have)
var emptyCard = load("res://resources/empty.tres")
var emptyCardSerialized = emptyCard.serialize()
#endregion


#region Basic Server Functions
func _ready():
	# make some data constant
	emptyCardSerialized.make_read_only()
	
	# connect multiplayer signals
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
#endregion

var levelNode

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
		playerNumbers[id] = players[id].playerNumber
		# TODO change from hard coded deck
		players[id].deck = load("res://data/decks/Default Stickman.tres")
		players[id].deck.ready()
		players[id].ready()
	
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
	playerNumbers[id] = player.playerNumber
	
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
	
	# CRITICAL check if syntax changed or something stupid
	levelNode = get_tree().root.get_child(0)

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
		approveGameStateChange.rpc({"name": "Card Draw"})
#endregion

#region Deserialization
## This serializes certain objects into a dictionary.
## This is inteended to be used in combination with RPCs.
## Currently supports:
## * []
## @experimental
func serialize(object: Variant) -> Dictionary:
	print("Failed to serialize object (Lobby autoload script). Returning empty dictionary...")
	return {}

## This deserializes certain objects from a dictionary.
## This is intended to be used in combination with RPCs.
## Currently supports:
## * []
## @experimental
func deserialize(_object: Dictionary) -> Variant:
	if not _object.has("type"): # if the dictionary is missing a valid type
		return null
	
	var object: Variant
	# object has a subtype
	if _object.has("subtype") and _object.subtype != "":
		match _object.subtype:
			"Entity":
				object = Entity.new()
			"AttackDirect":
				object = AttackDirect.new()
			_:
				return null
	else:
		match _object.type:
			"Card":
				object = Card.new()
			"Player":
				object = Player.new()
			"Deck":
				object = Deck.new()
			"Ability":
				object = Ability.new()
			_:
				return null
	
	# request the object to deserialize the data.
	object.deserialize(_object)
	return object
#endregion

#region Game Logic & Update Pushes
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





## CRITICAL vulnerable to the wrong player making requests
## Called when the game stage is to change.
## Can be called by anyone, but only takes effect if the correct person calls it.
## Additionally, calling this during the card selection phase marks that the player who called it is ready.
## @experimental Moving to remove the ID paramter
@rpc("any_peer", "reliable", "call_local")
func changeGameState(id: int):
	if multiplayer.is_server():
		# if the current state of the game is ...,
		match gameState["name"]:
			"Lobby":
				approveGameStateChange.rpc({"name": "Card Draw"})
			"Card Draw":
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
					approveGameStateChange.rpc({"name": "Turn", "player": 1})
			"Turn":
				# if the right player requests a game state change,
				if playerNumbers[id] == gameState["player"]:
					match playerNumbers[id]:
						1:
							approveGameStateChange.rpc({"name": "Turn", "player": 2})
						2:
							approveGameStateChange.rpc({"name": "Battle", "lane": 0})
			"Battle":
				# CRITICAL TODO ensure validity
				match gameState.lane:
					0: # lane 1 is done fighting,
						approveGameStateChange.rpc({"name": "Battle", "lane": 1})
					1:
						approveGameStateChange.rpc({"name": "Battle", "lane": 2})
					2:
						approveGameStateChange.rpc({"name": "Battle", "lane": 3})
					3:
						approveGameStateChange.rpc({"name": "Battle", "lane": 4})
					4:
						# don't worry---an RPC call to this exact function will be made.
						serverNextRound()
					_:
						print("requestGameStateChange call failed.")
						return
	# TODO decide if this is the right client to call
	# TODO implement turn code
	# TODO call this after lobby creation
	# TODO ensure that the clients have been notified

## Called when the server wants the game state to change.
## To get the game state to change, call "changeGameState" on the server using rpc_id
@rpc("authority", "reliable", "call_local")
func approveGameStateChange(newGameState: Dictionary):
	var oldGameState: Dictionary = gameState
	
	print("Game state change approved: ", newGameState)
	gameState = newGameState
	
	gameStateChange.emit(oldGameState)
	
	# additional code to run by the server:
	if multiplayer.is_server():
		match gameState.name:
			"Battle":
				battle(gameState.lane)

## Called when all players' turns have expired and a new round start. Should ONLY be called by the host.
func serverNextRound():
	gameRound += 1
	var signalsToFire = []

	var allIDs = players.keys()
	# give energy
	if gameRound < 10:
		setEnergy.rpc(allIDs, gameRound)
	else:
		setEnergy.rpc(allIDs, 10)
	
	# draw cards
	
	# go back to player 1's turn
	approveGameStateChange.rpc({"name": "Turn", "player": 1})


#region Change Player Stats
## Called by the server when someone's energy is set to a specific value (NOT added)
## Separate calls will separate the animations.
@rpc("authority", "call_local", "reliable")
func setEnergy(targetIDs: Array[int], energyCount: int):
	var oldEnergies: Array[int] = []
	for i in targetIDs:
		oldEnergies.append(players[i].energy)
		players[i].energy = energyCount
		
	playerEnergyUpdated.emit(targetIDs, oldEnergies, true)

## Called by the server when someone's health changes.
## To be sparingly used. Resort to attacks and abilities instead.
## Separate calls will separate the animations.
@rpc("authority", "call_local", "reliable")
func setHealth(targetIDs: Array[int], healthCount: int):
	var oldHealths: Array[int] = []
	for i in targetIDs:
		oldHealths.append(players[i].health)
		players[i].health = healthCount
		
	playerHealthUpdated.emit(targetIDs, oldHealths, true)


## Called by the server when someone's energy changes.
## Separate calls will separate the animations.
## In this case, gaining 1 energy and then another energy is different from gaining 2 energy straight away due to animations being played and abilities being triggered, etc.
@rpc("authority", "call_local", "reliable")
func giveEnergy(targetIDs: Array[int], energyCount: int):
	var oldEnergies: Array[int] = []
	for i in targetIDs:
		oldEnergies.append(players[i].energy)
		players[i].energy += energyCount
		
	playerEnergyUpdated.emit(targetIDs, oldEnergies, false)

## Called by the server when someone's health changes.
## To be sparingly used. Resort to attacks and abilities instead.
## Separate calls will separate the animations.
## In this case, gaining 1 energy and then another energy is different from gaining 2 energy straight away due to animations being played and abilities being triggered, etc.
@rpc("authority", "call_local", "reliable")
func giveHealth(targetIDs: Array[int], healthCount: int):
	var oldHealths: Array[int] = []
	for i in targetIDs:
		oldHealths.append(players[i].health)
		players[i].health += healthCount
		
	playerHealthUpdated.emit(targetIDs, oldHealths, false)
#endregion

## The move parameter will change to a Dictionary in the future. TODO
## CRITICAL vulnerable to exploits
## Locations as seen by the player
## @deprecated
# TODO fix up RPC parameters
@rpc("any_peer", "call_local", "reliable")
func requestMove(id: int, _move: String, attackerLocation: Array[int], targetLocation: Array[int]):
	if multiplayer.is_server():
		var actualAttackerLocation: Array[int] = attackerLocation
		var actualTargetLocation: Array[int] = targetLocation
		# WARNING hard coded
		if id != 1:
			actualAttackerLocation[0] = 3 - attackerLocation[0]
			actualTargetLocation[0] = 3 - targetLocation[0]
		
		# if the right person has called the function,
		# if the attacker is a valid card (belonging AND existence),
		# if the target is a valid card (existence),
		# WARNING hard coded
		if playerNumbers[id] == gameState.player and (attackerLocation[0] == 0 or attackerLocation[0] == 1) and activeCards[attackerLocation[0]][attackerLocation[1]] != null and activeCards[targetLocation[0]][targetLocation[1]] != null:
			# process move logic
			for i in players:
				if id == i: # if this is the player that sent it (the locations are accurate from their perspective),
					approveMove.rpc_id(i, id, _move, attackerLocation, targetLocation)
				else: # if this is the server and the opponent sent in the request,
					approveMove.rpc_id(i, id, _move, actualAttackerLocation, actualTargetLocation)
		# TODO process move logic
		# TODO ensure updates are pushed

## The move parameter will change to a Dictionary in the future. TODO
## @deprecated
@rpc("authority", "call_local", "reliable")
func approveMove(id: int, _move: String, attackerLocation: Array[int], targetLocation: Array[int]):
		if _move == "AttackDirect":
			# TODO complete with dynamic strengths, etc.
			var move = AttackDirect.new()
			move.base_damage = 1
			
			move.execute(activeCards[targetLocation[0]][targetLocation[1]], activeCards[attackerLocation[0]][attackerLocation[1]])

## called when a client requests to change the active move of a card active on the field.
# TODO fix up RPC parameters
@rpc
func changeActiveMove():
	# TODO ensure the right person has called the function at the right time
	# TODO ensure updates are pushed
	pass

#region Inform Client of Attacks and Moves TODO change this name
# what the hell is this? WARNING
func changeCardHealth(target: Card, oldCardHealth: int):
	print("The card's health changed gained by ", target.health - oldCardHealth)


#endregion

#region Battle logic
## lane: The lane variable refers to the array index of the lane (0-4)
func battle(lane: int):
	var itemsToExecute: Array[Dictionary] = []
	
	# have all (both) cards attack each other at the same time
	var cardsInLane: Array = [activeCards[0][lane], activeCards[1][lane]]
	var target = null
	var nextCard = null
	var nextItemToExecute: Dictionary = {}
	# WARNING hard-coded
	for i in range(0, 2):
		nextCard = cardsInLane[i]
		
		# only execute moves on cards that actually exist.
		if nextCard == null:
			continue
		
		# WARNING hard-coded
		# cards currently always attack straight. More logic will be needed if they don't.
		# TODO custom targetting function that can be called by any move or ability
		if cardsInLane[1 - i] == null: # if there is no card to block the attack,
			# attack the opposing player.
			# remember that i = 0 means that a card is related to player 1.
			# WARNING hard-coded
			if i == 0: # if the card is player 1's card,
				target = 2
			else:
				target = 1
		else:
			target = cardsInLane[1 - i]
		
		nextItemToExecute = nextCard.execute(target)
		if not nextItemToExecute.is_empty(): # if there are stats to update or animations to play,
			itemsToExecute.append(nextItemToExecute)
	
	# tell everyone to display animations and update card stats.
	execute.rpc(itemsToExecute)

# TODO make description useful and informative
## Called by the server to indicate that stats for Entities and/or Players have changed.
## All animations are to be called at once.
## Emits signals for other nodes to do processing and animations. Also does processing when necessary.
## Valid target dictionary: {
##	target: grid tile index (e.g. [0, 4]) or player number (e.g. 2).
##	cause: the location from where this attack originates from. There are four different values this can take:
##		* Array, representing the grid index
##		* "Special", representing a special
##		* Int, representing which Environment it came from
##		* null, the source is irrelevant
##		NOTE: the only important information "cause" gives is the location from where the attack animation should begin. (e.g. client knows to tell the 5th lane's environment to play its animation)
##	type: one of these: "Card Draw", "Summon", "Attack", "Buff", "Debuff", "Kill", "Ability"
##	directAttack: true/false
##	statChange: 
##		# TODO fix this comment here{
##		Key names should be similar to the parameters of the object being changed.
##	}
## }
## NOTE: the order of the targets array should not matter.
## The next gameplay functions are to be called once the host has finished playing the animations.
@rpc("authority", "call_local", "reliable")
func execute(targets: Array[Dictionary]):
	# start executing EVERY stat change animation right now
	for i in targets:
		# TODO ensure validity
		# TODO type safety
		#if not (i.has("target") && i.has("directAttack") && i.has("statChange") && i.has("cause") && i.has("type")):
			# TODO dispute packet with server
			#continue
		
		match i["type"]:
			"Card Draw":
				drawCard(i.target) # the target should be a player.
			"Summon":
				summon.emit(i.target, deserialize(i.statChange))
			"Attack":
				attack.emit(i.target, i.cause, i.statChange, i.directAttack)
			"Buff":
				buff.emit(i.target, i.cause, i.statChange, i.directAttack)
			"Debuff":
				debuff.emit(i.target, i.cause, i.statChange, i.directAttack)
			"Kill":
				kill.emit(i.target)
			"Ability":
				ability.emit(i.target, deserialize(i.statChange))
			_: # if they didn't give a valid type,
				continue # ignore this entire request
#endregion

#@rpc("authority", "call_local", "reliable")
#func changeEnvironment(newEnvironment: Dictionary, lane: int):
	#pass
#region Card Gain
## The function that handles a player drawing a card from their deck.
## Only to be called on the server.
func drawCard(target: int, deckIndex: int = -1):
	# CRITICAL TODO pop cards as they come out
	handOverCard(target, players[target].deck.cardContents[deckIndex].serialize())

## The function that gets called when someone is to receive a card (not necessarily a draw card function)
## EVERY person will be notified that the card has been drawn. However, only the relevant player will know exactly what card has been drawn.
## This function has a special behaviour when the player's inventory is already full TODO @experimental
## The target parameter refers to the player (ID) who has received the card.
@rpc("authority", "call_local", "reliable")
func handOverCard(target: int, _card: Dictionary):
	var card: Card = deserialize(_card)
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
				handOverCard.rpc_id(i, target, emptyCardSerialized)

## The function that gets called when someone is to receive multiple cards at once (not necessarily a draw card function)
## EVERY person will be notified that the card has been drawn. However, only the relevant player will know exactly what card has been drawn.
## This function has a special behaviour when the player's inventory is already full TODO @experimental
## The target parameter refers to the player (ID) who has received the card.
@rpc("authority", "call_local", "reliable")
func handOverCards(target: int, _cards: Array[Dictionary]):
	var card: Card
	var oldInventorySize: int = len(players[target].inventory)
	var censoredCards = []
	
	for i in _cards:
		card = deserialize(i)
		
		censoredCards.append(emptyCardSerialized)
		
		# store the card in the right player
		players[target].inventory.append(emptyCard)
	
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
#endregion

#region Card Placement
## Called on the server when the user wishes to place down a card.
## Array indexes should be as they appear on the client
## The id should be the ID of the player who is placing the card down
## there are a couple requirements for card placement.
## First of all, it needs to be the respective player's turn.
## Second of all, the card needs to be in their inventory.
## Third of all, the location should be free.
# TODO integrate serialization
# TODO fix up which player is on which side (e.g. one player should always access the grid using 5 - index
@rpc("any_peer", "call_local", "reliable")
func requestCardPlacement(id: int, _card: Dictionary, location: Array[int]):
	# only the server should handle this request.
	if not multiplayer.is_server():
		return
	
	# TODO make it so that the client can't crash the server by giving an invalid card ID
	var card: Card = deserialize(_card)
	
	# card placement requirements
	var playerNumber = playerNumbers[id]
	var inventoryIndex = players[id].serializedInventory().find(_card)
	var originalLocation: Array[int] = location
	# WARNING hard-coded
	# CRITICAL TODO ensure player places on their own side of the lane
	if id != 1:
		location = [1 - location[0], location[1]]
	
	# WARNING hard-coded
	print("Processing request...", "Correct Player? ", playerNumber == gameState.player, " Correct Game State? ", gameState.name == "Turn", " Card Exists in Inventory? ", inventoryIndex != -1, " Free Spot on Board? ", activeCards[location[0]][location[1]] == null, " Correct Location? ", originalLocation[0] == 1, " Player can afford to play the card? ", players[id].energy >= card.cost)
	if playerNumber == gameState.player and gameState.name == "Turn" and inventoryIndex != -1 and activeCards[location[0]][location[1]] == null and originalLocation[0] == 1 and players[id].energy >= card.cost:
		# deduct energy
		# NOTE: removing "as Array[int]" will cause unexpected behaviour. GDScript is interesting.
		giveEnergy.rpc([id] as Array[int], -card.cost)
		
		# TODO optimize if statements
		for i in players: # tell everyone that there is a card placement and to start playing animations
			if i == 1:
				approveCardPlacement.rpc_id(i, id, _card, location)
			else:
				if id == 1: # if the host placed the card,
					approveCardPlacement.rpc_id(i, id, _card, [1 - location[0], location[1]] as Array[int])
				else:
					approveCardPlacement.rpc_id(i, id, _card, originalLocation)
	else: # reject.
		disapproveCardPlacement.rpc_id(id, id, _card, originalLocation)

@rpc("authority", "call_local", "reliable")
func disapproveCardPlacement(id: int, _card: Dictionary, location: Array[int]):
	if id == myID:
		levelNode.get_node("Grid").disapprovedCardPlacementRequest()

## Enter an ID of -1 if nobody initally requested for that exact card to be placed.
@rpc("authority", "call_local", "reliable")
func approveCardPlacement(id: int, _card: Dictionary, location: Array[int]):
	# WARNING: hard-coded
	
	levelNode.get_node("Grid").approvedCardPlacementRequest(id, _card, location)
	
	summon.emit(location, deserialize(_card))
#endregion
#endregion
