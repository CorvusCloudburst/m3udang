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
@onready var visualizer_panel_layout: VBoxContainer = $VisualizerPanelLayout

@onready var visualizer_select: OptionButton = $VisualizerPanelLayout/VisualizerPanelControls/VisualizerSelect
@onready var color_mode_select: OptionButton = $VisualizerPanelLayout/VisualizerPanelControls/ColorModeSelect
@onready var visualizer_color_button: ColorPickerButton = $VisualizerPanelLayout/VisualizerPanelControls/VisualizerColorButton
@onready var hue_shift_slider: HSlider = $VisualizerPanelLayout/VisualizerPanelControls/HueShiftSlider
@onready var element_count_spin_box: SpinBox = $VisualizerPanelLayout/VisualizerPanelControls/ElementCountSpinBox


var visualizer: Visualizer2D

# ------------- Initialization -------------
func _ready() -> void:
	_initialize_visualizer()
	
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
	_initialize_visualizer_select()
	_initialize_color_mode_select()
	visualizer_color_button.color = Color.MEDIUM_SLATE_BLUE
	element_count_spin_box.value = 64
	_update_visualizer_style()
	


# -----------------------------------------------------------------
# Process
# -----------------------------------------------------------------


# TODO NOTES FOR CORVUS:
#   - Implement Aurora similarly
	
func _update_visualizer_style() -> void:
	var was_playing = false
	
	if visualizer:
		was_playing = visualizer.playing
		visualizer.queue_free()
		
	match visualizer_select.selected:
		Visualizers.BARS: visualizer = preload("res://app/now_playing/visualizer/visualizers/bars.tscn").instantiate()
		# TODO: Implement AURORA style
		Visualizers.AURORA: visualizer = preload("res://app/now_playing/visualizer/visualizers/bars.tscn").instantiate()
		_: visualizer = preload("res://app/now_playing/visualizer/visualizers/bars.tscn").instantiate()
	
	visualizer.colorMode = VisualizerColors.ColorMode.values()[color_mode_select.selected]
	visualizer.color = visualizer_color_button.color
	visualizer.hue_shift = hue_shift_slider.value
	
	if (element_count_spin_box.value != visualizer.element_count):
		visualizer.update_element_count(element_count_spin_box.value as int)
	
	visualizer.playing = was_playing
	
	visualizer_panel_layout.add_child(visualizer)

# -----------------------------------------------------------------
# Controls
# -----------------------------------------------------------------

# Visualizer Style
func _on_visualizer_select_item_selected(_index: int) -> void:
	_update_visualizer_style()

# Color Mode
func _on_color_mode_select_item_selected(_index: int) -> void:
	_update_visualizer_style()

# Color
func _on_visualizer_color_button_color_changed(_color: Color) -> void:
	_update_visualizer_style()

# Hue Shift
func _on_hue_shift_slider_value_changed(_value: float) -> void:
	_update_visualizer_style()

# Element Count
func _on_element_count_spin_box_value_changed(_value: float) -> void:
	_update_visualizer_style()
