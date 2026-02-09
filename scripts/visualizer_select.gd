extends OptionButton

var visualizer_types: PackedStringArray = [
	"Bars (Static Rainbow)",
	"Bars (Dynamic Rainbow)",
	"Bars (Static Theme)",
	"Bars (Dynamic Theme)",
	"Aurora (Rainbow)",
	"Aurora (Theme)",
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for index in visualizer_types.size():
		add_item(visualizer_types[index], index)
