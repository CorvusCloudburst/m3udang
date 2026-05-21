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
@onready var color_mode_select: OptionButton = $VisualizerPanelLayout/VisualizerPanelControls/ColorModeSelect
@onready var visualizer_panel_layout: VBoxContainer = $VisualizerPanelLayout

var visualizer: Visualizer2D

# ------------- Initialization -------------
func _ready() -> void:
	_initialize_visualizer_select()
	_initialize_visualizer()
	_initialize_color_mode_select()
	
func _initialize_visualizer_select() -> void:
	visualizer_select.clear()
	for index in VisualizerStyles.size():
		visualizer_select.add_item(VisualizerStyles[index], index)
	visualizer_select.select(Visualizers.BARS)
	
func _initialize_color_mode_select() -> void:
	color_mode_select.clear()
	for index in VisualizerColors.ColorModeLabels.size():
		color_mode_select.add_item(VisualizerColors.ColorModeLabels[index], index)
	color_mode_select.select(VisualizerColors.ColorMode.MONO)
	
func _initialize_visualizer() -> void:
	_update_visualizer_style(Visualizers.BARS, VisualizerColors.ColorMode.MONO)
	


# -----------------------------------------------------------------
# Process
# -----------------------------------------------------------------


# TODO NOTES FOR CORVUS:
#   - Add visualizer controls for every value (still left - color, hue shift, element count)
#   - Implement Aurora similarly
#   - Make actual icons for the repeat mode button
#   - Add tooltips
	
func _update_visualizer_style(style: Visualizers, colorMode: VisualizerColors.ColorMode) -> void:
	var was_playing = false
	
	if visualizer:
		was_playing = visualizer.playing
		visualizer.queue_free()
		
	match style:
		Visualizers.BARS: visualizer = preload("res://app/now_playing/visualizer/visualizers/bars.tscn").instantiate()
		# TODO: Implement AURORA style
		Visualizers.AURORA: visualizer = preload("res://app/now_playing/visualizer/visualizers/bars.tscn").instantiate()
		_: visualizer = preload("res://app/now_playing/visualizer/visualizers/bars.tscn").instantiate()
	
	visualizer.colorMode = colorMode
	visualizer.playing = was_playing
	
	visualizer_panel_layout.add_child(visualizer)

# -----------------------------------------------------------------
# Controls
# -----------------------------------------------------------------

# Visualizer Style
func _on_visualizer_select_item_selected(index: int) -> void:
	_update_visualizer_style(index, visualizer.colorMode)

# Color Mode
func _on_color_mode_select_item_selected(index: int) -> void:
	_update_visualizer_style(visualizer_select.selected, index)
