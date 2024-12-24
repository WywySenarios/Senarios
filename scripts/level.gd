extends Node2D


## stores the current player
var me: Player = Lobby.players[Lobby.myID]

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
	# server gives the player a new card to look at during the card selection phasea
	# card drawing phase is over
	# phase change in the game
	# someone's energy has changed
	# someone's health has changed
	
	# start the card drawing phase
	# Tell server you have drawn the cards from the deck
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## Called during the card selection phase after the server approves the player to 
func changeCardSelectionCard(newCard: Card):
	# TODO implement
	pass

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
	# TODO Reflect GUI change of the turn button
	pass
