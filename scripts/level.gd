extends Control

## Stores the current stage of the game:
## {
##	name: "Lobby", Card Draw", "Turn"; String
##	player: 1 # the respective player. If there is no player related to the game state, this should have a value of -1, NaN, null, etc.; Integer
## }
var gameState: Dictionary = {
	"name": "Card Draw",
	"player": -1
}

var cardDrawNodes: Array[Node]

var myNode
var opponentNode

## Runtime variable intended to store where the player is focusing
var focusedNode: Node
## Runtime variable intended to store which node the player has selected
var lastClickedNode: Node
## Runtime variable intended to store if an animation should be playing right now.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# register this scene with the server autoload script
	Lobby.levelScene = self
	
	# set the place where the cards will spawn when the gain card animation starts playing
	# TODO the above comment needs to be clarified later.
	$"Inventories/Far Inventory".cardSpawnPoint = $"Card Spawn Point"
	$"Inventories/My Inventory".cardSpawnPoint = $"Card Spawn Point"
	
	# register child nodes
	cardDrawNodes = [$"Card Draw Ready Button", $"Card Draw"]
	myNode = $"Players/Me"
	opponentNode = $"Players/Far"
	
	# register players nodes' player variables (DIRECTLY link to server, no pipelining variables anymore :)
	for i in Lobby.players:
		if i == Lobby.myID:
			myNode.addPlayer(Lobby.players[i])
		else:
			opponentNode.addPlayer(Lobby.players[i])
	
	# register this node with the server
	Lobby.levelNode = self
	
	# Connect signals to the server
	Lobby.newCard.connect(changeCardSelectionCard) # server gives the player a new card to look at during the card selection phase
	Lobby.gameStateChange.connect(changeGameState) # Game Stage Change
	# card drawing phase is over
	Lobby.inventorySizeIncreased.connect(gainCardAnimation) # card has been given to a player
	Lobby.playerEnergyUpdated.connect(changeEnergy) # someone's energy has changed
	Lobby.playerHealthUpdated.connect(changeHealth) # someone's health has changed
	# game has ended
	Lobby.gameLost.connect(onGameEnd)
	
	# If you are the host, calling this will enable the card selection phase to start
	Lobby.preGame()
	
	# start the card drawing phase
	# TODO Make everything that is not card selection related somewhat transparent
	# inventories
	# grid
	# HUD
	# Make card selection items visible
	# Connect signals for user input
	$"Card Draw/0".clicked.connect(cardWish)
	$"Card Draw/1".clicked.connect(cardWish)
	$"Card Draw/2".clicked.connect(cardWish)
	$"Card Draw/3".clicked.connect(cardWish)

## Send a request to the server to switch cards
## The singular parameter is a draw_card scene.
func cardWish(cardNode: Control) -> void:
	# redundant check for valid input
	if 0 <= cardNode.index and cardNode.index <= 3:
		# send a request to the server. Updates will be handled in another function (changeCardSelectionCard)
		Lobby.rerollWish.rpc_id(1, cardNode.index, Lobby.myID)

## Called during the card selection phase after the server gives the player their starting cards, OR the server approves the player to switch cards
func changeCardSelectionCard(index: int, newCard: String) -> void:
	var relevantNode: Control = null
	
	# I actually can't fathom why get_node can't take in a string. This is absolutely stupid.
	if index > 3:
		relevantNode = $"Card Draw".get_node(NodePath(str(index - 4)))
	else:
		relevantNode = $"Card Draw".get_node(NodePath(str(index)))
	
	# Type safety (null check)
	if relevantNode == null:
		print("Card selection card's node was null. Aborting update...", NodePath(str(index)), ", ", Lobby.myID)
		return
	
	# WARNING hard-coded
	relevantNode.reassignCard(index, newCard)

#region Animations
## Does not guarentee that the correct energy change has been displayed (if the client's current energy reading is wrong).
## However, this function updates the GUI so that the correct energy count is displayed for the respective player.
## The targets array should contain the ID recognized by the server (e.g. the host is 1)
## WARNING hard-coded
func changeEnergy(targets: Array[int], oldEnergies: Array[int], wasSet: bool) -> void:
	for i in range(len(targets)):
		match targets[i]:
			Lobby.myID:
				myNode.changeEnergy(targets[i], oldEnergies[i])
			_:
				opponentNode.changeEnergy(targets[i], oldEnergies[i])

## Does not guarentee that the correct HP change has been displayed.
## However, this function updates the GUI so that the correct HP count is displayed for the respective player.
## The targets array should contain the ID recognized by the server (e.g. the host is 1)
## WARNING hard-coded
func changeHealth(targets:  Array[int], oldHealths: Array[int], wasSet: bool) -> void:
	for i in range(len(targets)):
		match targets[i]:
			Lobby.myID:
				myNode.changeEnergy(targets[i], oldHealths[i])
			_:
				opponentNode.changeEnergy(targets[i], oldHealths[i])

func gainCardAnimation(id: int, oldInventorySize: int, card) -> void:
		
	
	if (id == Lobby.myID): # if I am gaining the card,
		# determine how many cards are coming in
		if typeof(card) == TYPE_ARRAY: # if it's an array and therefore multiple cards are coming in,
			$"Inventories/My Inventory".addCards(card)
		else: # if it's a single card,
			$"Inventories/My Inventory".addCard(card)
		
	# TODO more than one player expandability
	else: # the opponent is gaining a card:
		# determine how many cards are coming in
		if typeof(card) == TYPE_ARRAY: # if it's an array and therefore multiple cards are coming in,
			$"Inventories/Far Inventory".addCards(card)
		else: # if it's a single card,
			$"Inventories/Far Inventory".addCard(card)
#endregion


#region Game State Functions
## Function to be called when the game state changes.
func changeGameState(oldGameState: Dictionary) -> void:
	# update the game state
	gameState = Lobby.gameState
	
	match (oldGameState.name):
		"Lobby":
			# disable next turn button
			$"Player HUD/Next Turn Button".disabled = true
		"Card Draw":
			# Hide card draw elements
			for i in cardDrawNodes:
				# Make the element transparent by setting its CanvasItems Modulate property's alpha channel to 0
				# Animation time is 0.5s
				get_tree().create_tween().tween_property(i, "modulate", Color(i.modulate, 0), 0.5)
				
				# also hide the elements after the animation
				get_tree().create_tween().tween_callback(i.queue_free).set_delay(0.5)
				
				# TODO make the gameplay elements less transparent.
		"Turn":
			# disable next turn button
			$"Player HUD/Next Turn Button".disabled = true
		"Battle":
			# TODO unhighlight the old lane
			pass
	
	# what do we do with the new (current) game state?
	match (gameState.name):
		"Card Draw":
			# Show card draw elements
			for i in cardDrawNodes:
				i.show()
		"Turn":
			# show the next turn button if it's your turn
			if Lobby.gameState["player"] == Lobby.playerNumbers[Lobby.myID] and Lobby.gameState["name"] == "Turn": # if the new game state is my turn
				$"Player HUD/Next Turn Button".disabled = false
		"Battle":
			print("Battle! Lane: ", gameState.lane) # TODO make this line unecessary
	
	# TODO Reflect GUI change of the turn button
	pass

func _on_button_button_up() -> void:
	# Tell the server that I am done selecting my starting hand
	Lobby.changeGameState.rpc_id(1, Lobby.myID)


func requestTurnChange() -> void:
	# redundant check for valid input
	if Lobby.gameState["player"] == Lobby.playerNumbers[Lobby.myID] and Lobby.gameState["name"] == "Turn":
		print_debug("Requesting turn change...")
		Lobby.changeGameState.rpc_id(1, Lobby.myID)

func onGameEnd(loser: int) -> void:
	if loser == Lobby.playerNumbers[Lobby.myID]:
		$"End Game Message".text = "You lost!"
	else:
		$"End Game Message".text = "You won!"
	
	$"End Game Message".show()
	$"End Game Button".show()
#endregion

func prompt(_prompt: Dictionary) -> void:
	$"Current Prompt".text = _prompt.message
	$"Current Prompt".show()

func clearPrompt() -> void:
	$"Current Prompt".hide()


func onMainMenuButtonUp() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
