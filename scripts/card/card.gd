extends Resource
class_name Card

@export var name : String = "N/A"
@export var cardType : String = ""
@export_range(1, 6) var generation : int
@export var cost : float = 0
@export var type : Array[String]
@export var image : CompressedTexture2D
