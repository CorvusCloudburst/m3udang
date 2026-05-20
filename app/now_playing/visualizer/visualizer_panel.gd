extends Panel

# -----------------------------------------------------------------
# Setup
# -----------------------------------------------------------------

# Static Constants
enum Visualizers {
	BARS,
	AURORA, 
}

static var VisualizerStyles = {
	Visualizers.BARS: "Bars",
	Visualizers.AURORA: "Aurora",
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
	for index in VisualizerStyles.size():
		visualizer_select.add_item(VisualizerStyles[index], index)
	visualizer_select.select(Visualizers.BARS)

func _initialize_visualizer() -> void:
	_update_visualizer_style(Visualizers.BARS)

func _update_visualizer_style(style: Visualizers) -> void:
	if visualizer:
		visualizer.queue_free()
		
	match style:
		Visualizers.BARS: visualizer = preload("res://app/now_playing/visualizer/visualizers/bars.tscn").instantiate()
		Visualizers.AURORA: visualizer = preload("res://app/now_playing/visualizer/visualizers/bars.tscn").instantiate()
		_: visualizer = preload("res://app/now_playing/visualizer/visualizers/bars.tscn").instantiate()
	
	visualizer_panel_layout.add_child(visualizer)
	


# -----------------------------------------------------------------
# Process
# -----------------------------------------------------------------


# TODO NOTES FOR CORVUS:
#   - Add visualizer controls for every value (color, hue shift, color mode)
#   - Implement Aurora similarly
#   - Add a fucking volume slider
#   - Make actual icons for the repeat mode button
#   - Add tooltips
	

# -----------------------------------------------------------------
# Controls
# -----------------------------------------------------------------

# Visualizer Style
func _on_visualizer_select_item_selected(index: int) -> void:
	_update_visualizer_style(index)
