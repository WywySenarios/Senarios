extends Node2D

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
func _ready():
	# Connect signals to the server
	Lobby.newCard.connect(changeCardSelectionCard) # server gives the player a new card to look at during the card selection phase
	# card drawing phase is over
	# phase change in the game
	# someone's energy has changed
	# someone's health has changed
	
	# start the card drawing phase
	# Make everything that is not card selection related somewhat transparent
	# inventories
	# grid
	# HUD
	# Make card selection items visible
	# Connect signals for user input
	for i in $"Card Draw".get_children():
		i.clicked.connect(cardWish)
	
	# Tell server you have drawn the cards from the deck
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## Send a request to the server to switch cards
## The singular parameter is a draw_card scene.
func cardWish(cardNode: Node2D):
	# redundant check for valid input
	if 0 <= cardNode.index and cardNode.index <= 3:
		# send a request to the server. Updates will be handled in another function (changeCardSelectionCard)
		Lobby.rerollWish.rpc_id(1, cardNode.index, Lobby.myID)

## Called during the card selection phase after the server gives the player their starting cards, OR the server approves the player to switch cards
func changeCardSelectionCard(index: int, newCard: Card):
	print('changeCardSelectionCard')
	# TODO implement
	var relevantNode: Node2D
	if index > 3:
		$"Card Draw".get_node(str(index - 4))
	else:
		$"Card Draw".get_node(str(index))
	
	# Type safety (null check)
	if relevantNode == null:
		print("Card selection card's node was null. Aborting update...")
		return
	
	relevantNode.reassignCard(index, newCard)

## Does not guarentee that the correct energy change has been displayed (if the client's current energy reading is wrong).
## However, this function updates the GUI so that the correct energy count is displayed for the respective player.
## The playerID should be the ID recognized by the server (e.g. the host is 1)
func gainEnergy(finalEnergy: int, playerID: int):
	# TODO change the text of the GUI element
	pass

## Does not guarentee that the correct HP change has been displayed.
## However, this function updates the GUI so that the correct HP count is displayed for the respective player.
## The playerID should be the ID recognized by the server (e.g. the host is 1)
func changePlayerHP(finalHP: int, playerID: int):
	# TODO change the text of the respective GUI element
	pass

## Function to be called when the game state changes.
## @experimental
func changeGameState(newState: String):
	if gameState.name == "Card Draw": # if the current game state is the card drawing phase,
		pass# make the gameplay elements less transparent.
	
	# TODO Reflect GUI change of the turn button
	pass
