# Useful resources for understanding this script:
# - Original setup: https://www.youtube.com/watch?v=TFNfzf_H530
# - Better spectrum math: https://www.youtube.com/watch?v=jttL809UdnQ
# - Inheritance in Godot: https://www.youtube.com/watch?v=LncJsj1vqSM

class_name Visualizer
extends TextureRect

# -----------------------------------------------------------------
# Common properties
# -----------------------------------------------------------------

@export var gradient: Gradient
@export var responsiveColorShift: bool
@export var hue_shift: float = 0.0

var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
var elements: Array[VisualizerElement]
var element_count: int

var portioned_width: float
var portioned_height: float

var lerp_weight: float


# -----------------------------------------------------------------
# Common functions
# -----------------------------------------------------------------

func _ready() -> void:
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spectrum_analyzer = AudioServer.get_bus_effect_instance(0,0)
	for i: int in element_count:
		elements.append(VisualizerElement.new())

func _process(_delta: float) -> void:
	portioned_width = size.x / float(element_count)
	portioned_height = size.y / float(element_count)
	if Globals.playing:
		update_spectrum_data()
		queue_redraw() # Draw function implemented by subclasses

func update_spectrum_data() -> void:
	for i: int in element_count:
		elements[i].update_values(spectrum_analyzer, i, element_count, lerp_weight, size.x * 10, size.y * 15)


# -----------------------------------------------------------------
# Color management
# -----------------------------------------------------------------

func static_color(index: int) -> Color:
	var color = gradient.sample(float(index) / float(element_count))
	color.h = shifted_hue_value(color)
	return color
	
func responsive_color(index: int) -> Color:
	var color = gradient.sample(elements[index].energyCurrent)
	color.h = shifted_hue_value(color)
	return color
	
func shifted_hue_value(color: Color) -> float:
	var shifted_hue = color.h + hue_shift
	if shifted_hue > 1:
		shifted_hue -= 1
	return shifted_hue
	
