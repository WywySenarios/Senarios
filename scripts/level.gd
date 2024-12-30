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
			myNode.player = Lobby.players[i]
		else:
			opponentNode.player = Lobby.players[i]
	
	# register this node with the server
	Lobby.levelNode = self
	
	# Connect signals to the server
	Lobby.newCard.connect(changeCardSelectionCard) # server gives the player a new card to look at during the card selection phase
	Lobby.gameStateChange.connect(changeGameState) # Game Stage Change
	# card drawing phase is over
	Lobby.inventorySizeIncreased.connect(gainCardAnimation) # card has been given to a player
	Lobby.gameStateChange.connect(onGameStateChange) # phase change in the game
	Lobby.playerEnergyUpdated.connect(myNode.changeEnergy) # someone's energy has changed
	Lobby.playerHealthUpdated.connect(myNode.changeHealth) # someone's health has changed
	
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass

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
	
	relevantNode.reassignCard(index, load("res://resources/" +  newCard + ".tres"))

## Does not guarentee that the correct energy change has been displayed (if the client's current energy reading is wrong).
## However, this function updates the GUI so that the correct energy count is displayed for the respective player.
## The playerID should be the ID recognized by the server (e.g. the host is 1)
func gainEnergy(finalEnergy: int, playerID: int) -> void:
	# TODO change the text of the GUI element
	pass

## Does not guarentee that the correct HP change has been displayed.
## However, this function updates the GUI so that the correct HP count is displayed for the respective player.
## The playerID should be the ID recognized by the server (e.g. the host is 1)
func changePlayerHP(finalHP: int, playerID: int) -> void:
	# TODO change the text of the respective GUI element
	pass

## Function to be called when the game state changes.
## @experimental
func changeGameState(oldState: String, oldPlayer: int) -> void:
	if oldState == "Lobby":
		# Show card draw elements
		for i in cardDrawNodes:
			i.show()
	elif oldState == "Card Draw":
		
		# Hide card draw elements
		for i in cardDrawNodes:
			# Make the element transparent by setting its CanvasItems Modulate property's alpha channel to 0
			# Animation time is 0.5s
			get_tree().create_tween().tween_property(i, "modulate", Color(i.modulate, 0), 0.5)
			
			# also hide the elements after the animation
			get_tree().create_tween().tween_callback(i.queue_free).set_delay(0.5)
			
			# TODO make the gameplay elements less transparent.
	
	# TODO Reflect GUI change of the turn button
	pass

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


func _on_button_button_up() -> void:
	# Tell the server that I am done selecting my starting hand
	Lobby.changeGameState.rpc_id(1, Lobby.myID)

func onGameStateChange(oldGameStateName: String, oldGameStatePlayer: int) -> void:
	if Lobby.gameState["player"] == Lobby.players[Lobby.myID].id and Lobby.gameState["name"] == "Turn": # if the new game state is my turn
		$"Player HUD/Next Turn Button".disabled = false
	else:
		$"Player HUD/Next Turn Button".disabled = true


func requestTurnChange() -> void:
	# redundant check for valid input
	if Lobby.gameState["player"] == Lobby.myID and Lobby.gameState["name"] == "Turn":
		print("Turn is going to change!")
		Lobby.changeGameState.rpc_id(1, Lobby.myID)
