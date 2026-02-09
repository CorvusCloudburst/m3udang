extends BoxContainer

@onready var visualizerTypeSelect = $VisualizerControls/VisualizerSelect

func _ready() -> void:
	$Visualizer.visualizerType = visualizerTypeSelect.get_item_text(0)
	updateControls()

# ------------- Visualizer Type --------------------------
func _on_visualizer_select_item_selected(index: int) -> void:
	$Visualizer.visualizerType = visualizerTypeSelect.get_item_text(index)
	updateControls()

func _on_shift_slider_value_changed(value: float) -> void:
	$Visualizer.shift = value
	
func updateControls() -> void:
	var selectedTypeString: String = visualizerTypeSelect.get_item_text(visualizerTypeSelect.get_selected_id())
	$VisualizerControls/ShiftSlider.visible = selectedTypeString.contains("Rainbow")
