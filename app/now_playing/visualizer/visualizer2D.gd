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

func _process(_delta: float) -> void:
	portioned_width = size.x / float(element_count)
	portioned_height = size.y / float(element_count)
	if playing:
		update_spectrum_data()
		queue_redraw()
		

func update_spectrum_data() -> void:
	for i: int in element_count:
		elements[i].update_values(spectrum_analyzer, i, element_count, lerp_weight, size.x, size.y * 13)

func update_playing_state(now_playing: bool) -> void:
	playing = now_playing



# -----------------------------------------------------------------
# Color management
# -----------------------------------------------------------------

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
	
# ------------- Convenience Gradients --------------------------
func rainbow_gradient() -> Gradient:
	var new_gradient := Gradient.new()
	for index: int in element_count:
		var index_shifted_color = Color.from_hsv((
			# Gay math
			element_count * hue_shift + index) / element_count, 
			0.6, 
			0.7, 
			0.9
		)
		new_gradient.add_point(
			# Normalize to 0.0 - 1.0 range ?
			1.0/float(element_count + 1) + float(index)/float(element_count+ 1), 
			index_shifted_color
		)
	# Remove preset points
	new_gradient.remove_point(0)
	new_gradient.remove_point(0)
	return new_gradient

func mono_gradient() -> Gradient:
	var new_gradient = Gradient.new()
	new_gradient.add_point(0, color.darkened(0.8))
	new_gradient.add_point(1, color.lightened(0.2))
	# Remove preset points
	new_gradient.remove_point(0)
	new_gradient.remove_point(0)
	return new_gradient
	
func flat_gradient() -> Gradient:
	var new_gradient = Gradient.new()
	new_gradient.add_point(0, color)
	new_gradient.add_point(1, color)
	# Remove preset points
	new_gradient.remove_point(0)
	new_gradient.remove_point(0)
	return new_gradient
