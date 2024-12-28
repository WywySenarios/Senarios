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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect signals to the server
	Lobby.newCard.connect(changeCardSelectionCard) # server gives the player a new card to look at during the card selection phase
	Lobby.gameStateChange.connect(changeGameState) # Game Stage Change
	# card drawing phase is over
	# phase change in the game
	# someone's energy has changed
	# someone's health has changed
	
	# If you are the host, calling this will enable the card selection phase to start
	Lobby.preGame()
	
	# start the card drawing phase
	# Make everything that is not card selection related somewhat transparent
	# inventories
	# grid
	# HUD
	# Make card selection items visible
	# Connect signals for user input
	$"Card Draw/0".clicked.connect(cardWish)
	$"Card Draw/1".clicked.connect(cardWish)
	$"Card Draw/2".clicked.connect(cardWish)
	$"Card Draw/3".clicked.connect(cardWish)
	
	# Tell server you have drawn the cards from the deck
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass

## Send a request to the server to switch cards
## The singular parameter is a draw_card scene.
func cardWish(cardNode: Node2D) -> void:
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
	if oldState == "Card Draw":
		# Hide card draw elements
		# Make the element transparent by setting its CanvasItems Modulate property's alpha channel to 0
		# Animation time is 0.5s
		get_tree().create_tween().tween_property($"Card Draw", "modulate", Color($"Card Draw".modulate, 0), 0.5)
		get_tree().create_tween().tween_property($"Card Draw Ready Button", "modulate", Color($"Card Draw Ready Button".modulate, 0), 0.5)
		
		# also hide the elements after the animation
		get_tree().create_tween().tween_callback($"Card Draw".queue_free).set_delay(0.5)
		get_tree().create_tween().tween_callback($"Card Draw Ready Button".queue_free).set_delay(0.5)
		
		pass# TODO make the gameplay elements less transparent.
	
	# TODO Reflect GUI change of the turn button
	pass


func _on_button_button_up() -> void:
	# Tell the server that I am done selecting my starting hand
	Lobby.changeGameState.rpc_id(1, Lobby.myID)
