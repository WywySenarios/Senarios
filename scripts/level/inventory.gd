extends Control

const INVENTORY_COLOR_WYWY: Color = Color(0xf9d91e, 0.1)
const INVENTORY_COLOR_STICKMAN: Color = Color(0xe1483a, 0.1) # this color is likely to be changed later.

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

## This ready function just ensures that the inventory has the right background color.
func _ready():
	$Background.color = INVENTORY_COLOR_STICKMAN
