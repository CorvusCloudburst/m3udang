extends BoxContainer

@onready var visualizerTypeSelect = $VisualizerControls/VisualizerSelect

func _ready() -> void:
	$VisualizerContainer.visualizer_type = visualizerTypeSelect.get_item_text(0)
	updateControls()

# ------------- Visualizer Type --------------------------
func _on_visualizer_select_item_selected(index: int) -> void:
	$VisualizerContainer.visualizer_type = visualizerTypeSelect.get_item_text(index)
	if $VisualizerContainer.visualizer_type.contains("Aurora"):
		$VisualizerContainer.texture = preload("res://packaging/night-sky.png")
		$VisualizerContainer.hue_shift = 0.4
	else:
		$VisualizerContainer.texture = null
	updateControls()

func _on_shift_slider_value_changed(value: float) -> void:
	$VisualizerContainer.hue_shift = value
	
func updateControls() -> void:
	var selectedTypeString: String = visualizerTypeSelect.get_item_text(visualizerTypeSelect.get_selected_id())
	$VisualizerControls/ShiftSlider.visible = selectedTypeString.contains("Rainbow")
