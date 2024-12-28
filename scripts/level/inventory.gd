extends Control

## specifies whether or not this is the current player's inventory or not
@export var isMyInventory: bool = false


## Inventory Width in pixels
const inventoryWidth = 1200

## Gap size between cards in pixels
var gapSize: int = 50

## The width of a card in pixels
var cardWidth: int = 250

var cards: Array[Control] = []

# Avoid having to load it again and again, thus saving a bit of runtime.
const cardScene = preload("res://Scenes/card.tscn")
