# Useful resources for understanding this script:
# - Original setup: https://www.youtube.com/watch?v=TFNfzf_H530
# - Better spectrum math: https://www.youtube.com/watch?v=jttL809UdnQ
# - Inheritance in Godot: https://www.youtube.com/watch?v=LncJsj1vqSM

class_name Visualizer2D
extends TextureRect

# -----------------------------------------------------------------
# Common properties
# -----------------------------------------------------------------

@export var gradient: Gradient
@export var hue_shift: float = 0.0
@export var playing: bool = false
@export var color: Color = Color.MEDIUM_SLATE_BLUE
@export var colorMode: VisualizerConstants.ColorMode = VisualizerConstants.ColorMode.MONO
@export var preferred_background: Texture = preload("res://packaging/black.png")

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
	# Listen for signals to change the playing state
	SignalBus.playing_toggled.connect(update_playing_state)
	elements.clear()
	spectrum_analyzer = AudioServer.get_bus_effect_instance(1,0)
	for i: int in element_count:
		elements.append(VisualizerElement.new())
	gradient = VisualizerConstants.get_gradient_for_color_mode(colorMode, color, element_count, hue_shift)

func _process(_delta: float) -> void:
	portioned_width = size.x / float(element_count)
	portioned_height = size.y / float(element_count)
	if playing:
		update_spectrum_data()
		queue_redraw()
		

func update_spectrum_data() -> void:
	for i: int in element_count:
		elements[i].update_values(spectrum_analyzer, i, element_count, lerp_weight, size.x, size.y * 13)

func update_element_count(new_count: int) -> void:
	elements.clear()
	element_count = new_count
	spectrum_analyzer = AudioServer.get_bus_effect_instance(1,0)
	for i: int in element_count:
		elements.append(VisualizerElement.new())

func update_playing_state(now_playing: bool) -> void:
	playing = now_playing



# -----------------------------------------------------------------
# Color management
# -----------------------------------------------------------------

func get_color_for_index(index: int) -> Color:
	match colorMode:
		VisualizerConstants.ColorMode.MONO, VisualizerConstants.ColorMode.PRISMATIC: return responsive_color(index)
		VisualizerConstants.ColorMode.RAINBOW, VisualizerConstants.ColorMode.STATIC: return static_color(index)
		VisualizerConstants.ColorMode.FLAT: return flat_color()
		_: return color

func flat_color() -> Color:
	var calculated_color = color
	calculated_color.h = shifted_hue_value(calculated_color)
	return calculated_color

func static_color(index: int) -> Color:
	var calucated_color = gradient.sample(float(index) / float(element_count))
	calucated_color.h = shifted_hue_value(calucated_color)
	return calucated_color
	
func responsive_color(index: int) -> Color:
	var calucated_color = gradient.sample(elements[index].energyCurrent)
	calucated_color.h = shifted_hue_value(calucated_color)
	return calucated_color
	
func shifted_hue_value(original_color: Color) -> float:
	var shifted_hue = original_color.h + hue_shift
	if shifted_hue > 1:
		shifted_hue -= 1
	return shifted_hue
	
