extends Panel

# -----------------------------------------------------------------
# Setup
# -----------------------------------------------------------------

# Static Constants
enum Visualizers {
	BARS,
	BARS_FLAT, 
	BARS_RAINBOW, 
	BARS_PRISMATIC, 
	AURORA, 
	AURORA_PRISMATIC 
}

static var VisualizerLabels = {
	Visualizers.BARS: "Bars",
	Visualizers.BARS_FLAT: "Bars (Flat)",
	Visualizers.BARS_RAINBOW: "Bars (Rainbow)",
	Visualizers.BARS_PRISMATIC: "Bars (Prismatic)",
	Visualizers.AURORA: "Aurora",
	Visualizers.AURORA_PRISMATIC: "Aurora (Prismatic)",
}

# Display elements
@onready var visualizer_select: OptionButton = $VisualizerPanelLayout/VisualizerPanelControls/VisualizerSelect
@onready var visualizer_panel_layout: VBoxContainer = $VisualizerPanelLayout

var visualizer: Visualizer2D

# Initialization
func _ready() -> void:
	_initialize_visualizer_select()
	_initialize_visualizer()
	
func _initialize_visualizer_select() -> void:
	visualizer_select.clear()
	for index in VisualizerLabels.size():
		visualizer_select.add_item(VisualizerLabels[index], index)
	visualizer_select.select(Visualizers.BARS)

func _initialize_visualizer() -> void:
	if visualizer:
		visualizer.queue_free()
	
	# TODO: Select this by menu
	visualizer = preload("res://app/now_playing/visualizer/visualizers/bars.tscn").instantiate()
	
	visualizer_panel_layout.add_child(visualizer)


# -----------------------------------------------------------------
# Process
# -----------------------------------------------------------------


	
	

# -----------------------------------------------------------------
# Controls
# -----------------------------------------------------------------
