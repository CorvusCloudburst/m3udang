# Useful resources for understanding this script:
# - Original setup: https://www.youtube.com/watch?v=TFNfzf_H530
# - Better spectrum math: https://www.youtube.com/watch?v=jttL809UdnQ
# - Inheritance in Godot: https://www.youtube.com/watch?v=LncJsj1vqSM

extends TextureRect

# ---------------------------------------

var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
@export var visualizer_type: String
@export var hue_shift: float

# Bar Visualizers
const RANGE_COUNT: int = 64
var spectrum: Array[VisualizerElement] = []
var bar_width: float = 0.0

# Reference gradients
var rainbow_gradient: Gradient = Gradient.new()

const LERP_WEIGHTS = {
	"Bars": 0.1,
	"Aurora": 0.05,
}

# ---------------------------------------
func _ready() -> void:
	spectrum_analyzer = AudioServer.get_bus_effect_instance(0,0)
	_on_resized()
	for i: int in RANGE_COUNT:
		spectrum.append(VisualizerElement.new())
		rainbow_gradient.add_point(1.0/float(RANGE_COUNT + 1) + float(i)/float(RANGE_COUNT + 1), static_rainbow(i))
	rainbow_gradient.add_point(1, static_rainbow(0))
	rainbow_gradient.remove_point(0)

# ---------------------------------------
func _process(_delta: float) -> void:
	if Globals.playing:
		_update_spectrum_data()
		queue_redraw()

# ---------------------------------------
func _draw() -> void:
	# Determine which visualizer to render and draw it.
	if visualizer_type.contains("Bars"):
		draw_bars()
	else:
		draw_aurora()
		
# ------------- Bars ---------------------------------------
func draw_bars() -> void:
	for i: int in RANGE_COUNT:
		
		var color: Color
		match visualizer_type:
			"Bars (Static Rainbow)": color = static_rainbow(i)
			"Bars (Dynamic Rainbow)": color = dynamic_rainbow(i)
			"Bars (Dynamic Theme)": color = dynamic_theme(i)
			_: color = Globals.themeColor
				
		var rectangle: Rect2 = Rect2(
			i * bar_width,            			# Position X
			size.y - spectrum[i].heightLerped,  # Position Y
			bar_width - 2,            			# Width
			spectrum[i].heightLerped            # Height
		)
		draw_rect(rectangle, color)
		
# ------------- Borealis ---------------------------------------
func draw_aurora() -> void:
	for i: int in RANGE_COUNT:

		var color: Color
		match visualizer_type:
			"Aurora (Static Rainbow)": color = static_rainbow(i)
			"Aurora (Rainbow)": color = dynamic_rainbow(i)
			"Aurora (Theme)": color = dynamic_theme(i)
			_: color = Globals.themeColor
		
		# Primary
		var color1 = Color(color)
		color1.a = spectrum[i].energyLerped * 7
		var rectangle: Rect2 = Rect2(
			i * bar_width - (bar_width * 3),    			# Position X
			0,  											# Position Y
			bar_width * 5.1,            					# Width
			(spectrum[i].heightLerped * 1.5) + (size.y/25)  # Height
		)
		draw_rect(rectangle, color1, true, -1.0,true)
		
		# Secondary
		var color2 = Color(color)
		color2.a = spectrum[i].energyLerped / 1.2
		var rectangle2: Rect2 = Rect2(
			i * bar_width - (bar_width * 3),    					# Position X
			0,  													# Position Y
			bar_width * 7.2,            							# Width
			((spectrum[i].heightLerped * 3) + (size.y * 0.8)) / 2 	# Height
		)
		draw_rect(rectangle2, color2, true, -1.0,true)
		
		# Tertiary
		var color3 = Color(color)
		color3.a = spectrum[i].energyLerped / 3
		var rectangle3: Rect2 = Rect2(
			i * bar_width - (bar_width * 3),    				# Position X
			0,  												# Position Y
			bar_width * 10.3,            						# Width
			((spectrum[i].heightLerped * 3) + size.y) / 1.5 	# Height
		)
		draw_rect(rectangle3, color3, true, -1.0,true)


# ---------------------------------------
# Color Management
# ---------------------------------------

# -------------
func static_rainbow(index: int) -> Color:
	return Color.from_hsv((RANGE_COUNT * hue_shift + index * 0.9) / RANGE_COUNT, 0.6, 0.7, 0.9)
	
# -------------
func dynamic_rainbow(index:int) -> Color:
	var shiftedValue = spectrum[index].energyCurrent + hue_shift
	if shiftedValue > 1.0:
		shiftedValue = shiftedValue - 1.0
	return rainbow_gradient.sample(shiftedValue)
	
# -------------
func dynamic_theme(index:int) -> Color:
	var color = Globals.themeColor
	var minValue = min(Globals.themeColor.v, 0.2)
	var maxValue = max(Globals.themeColor.v, 0.35)
	color.v = clamp(spectrum[index].energyCurrent * 1.75, minValue, maxValue)
	return color

# ---------------------------------------
func _update_spectrum_data() -> void:
	var lerp_weight_key = LERP_WEIGHTS.keys().filter(func(key): return visualizer_type.contains((key))).get(0)
	var lerp_weight = LERP_WEIGHTS[lerp_weight_key]
	
	for i: int in RANGE_COUNT:
		spectrum[i].update_values(spectrum_analyzer, i, RANGE_COUNT, lerp_weight, size.x * 10, size.y * 15)

# ---------------------------------------
func _on_resized() -> void:
	bar_width = size.x / RANGE_COUNT

	
	
