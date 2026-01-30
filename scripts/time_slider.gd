extends HSlider

var dragging: bool

func _process(_delta: float) -> void:
	if !dragging:
		min_value = 0
		max_value = Globals.songLength
		value = Globals.seconds
