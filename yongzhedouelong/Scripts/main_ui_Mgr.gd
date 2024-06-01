extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func pickUpPoker(number,flower):
	$CanvasLayer/PokerBar.pickUpCard(number,flower)
func dropUpPoker(number,flower):
	$CanvasLayer/PokerBar.dropUpCard(number,flower)
