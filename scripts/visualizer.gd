# Tutorial (Primary): https://www.youtube.com/watch?v=TFNfzf_H530
# Tutorial (Frequency math): https://www.youtube.com/watch?v=jttL809UdnQ

extends TextureRect

# ---------------------------------------
# Spectrum Info
const FREQ_MAX: float = 11050.0
const MIN_DB: int = 60
var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance

@export var visualizerType: String
@export var shift: float

# Bar Visualizers
const RANGE_COUNT: int = 64
var spectrum: Array[SpectrumRange] = []
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
		spectrum.append(SpectrumRange.new())
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
	if visualizerType.contains("Bars"):
		draw_bars()
	else:
		draw_aurora()
		
# ------------- Bars ---------------------------------------
func draw_bars() -> void:
	for i: int in RANGE_COUNT:
		
		var color: Color
		match visualizerType:
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
		match visualizerType:
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
	return Color.from_hsv((RANGE_COUNT * shift + index * 0.9) / RANGE_COUNT, 0.6, 0.7, 0.9)
	
# -------------
func dynamic_rainbow(index:int) -> Color:
	var shiftedValue = spectrum[index].energyCurrent + shift
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
	var lerp_weight_key = LERP_WEIGHTS.keys().filter(func(key): return visualizerType.contains((key))).get(0)
	var lerp_weight = LERP_WEIGHTS[lerp_weight_key]
	for i: int in RANGE_COUNT:
		# Represented frequency range
		spectrum[i].hz_start = (i * FREQ_MAX) / RANGE_COUNT
		spectrum[i].hz_end = ((i + 1) * FREQ_MAX) / RANGE_COUNT
		
		# Fancy sound stuff
		spectrum[i].magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(spectrum[i].hz_start, spectrum[i].hz_end).length()
		
		# Adjust energy values
		spectrum[i].energyCurrent = clampf((MIN_DB + linear_to_db(spectrum[i].magnitude)) / MIN_DB, 0, 1)
		if spectrum[i].energyCurrent > spectrum[i].energyHigh:
			spectrum[i].energyHigh = spectrum[i].energyCurrent
		else:
			spectrum[i].energyHigh = lerp(spectrum[i].energyHigh, spectrum[i].energyCurrent, lerp_weight)
		if spectrum[i].energyCurrent <= 0:
			spectrum[i].energyLow = lerp(spectrum[i].energyLow, spectrum[i].energyCurrent, lerp_weight)
		spectrum[i].energyLerped = lerp(spectrum[i].energyLow, spectrum[i].energyHigh, lerp_weight)
		
		# Adjust relative height values
		spectrum[i].heightCurrent = spectrum[i].energyCurrent * size.y * 15.0
		if spectrum[i].heightCurrent > spectrum[i].heightHigh:
			spectrum[i].heightHigh = spectrum[i].heightCurrent
		else:
			spectrum[i].heightHigh = lerp(spectrum[i].heightHigh, spectrum[i].heightCurrent, lerp_weight)
		if spectrum[i].heightCurrent <= 0:
			spectrum[i].heightLow = lerp(spectrum[i].heightLow, spectrum[i].heightCurrent, lerp_weight)
		spectrum[i].heightLerped = lerp(spectrum[i].heightLow, spectrum[i].heightHigh, lerp_weight)
		
		# Adjust relative width values
		spectrum[i].widthCurrent = spectrum[i].energyCurrent * size.x * 10.0
		if spectrum[i].widthCurrent > spectrum[i].widthHigh:
			spectrum[i].widthHigh = spectrum[i].widthCurrent
		else:
			spectrum[i].widthHigh = lerp(spectrum[i].widthHigh, spectrum[i].widthCurrent, lerp_weight)
		if spectrum[i].widthCurrent <= 0:
			spectrum[i].widthLow = lerp(spectrum[i].widthLow, spectrum[i].widthCurrent, lerp_weight)
		spectrum[i].widthLerped = lerp(spectrum[i].widthLow, spectrum[i].widthHigh, lerp_weight)

# ---------------------------------------
func _on_resized() -> void:
	bar_width = size.x / RANGE_COUNT

# ---------------------------------------
class SpectrumRange:
	var hz_start: float
	var hz_end: float
	var magnitude: float
	
	# Energy
	var energyLerped: float
	var energyCurrent: float
	var energyHigh: float
	var energyLow: float
	
	# Height
	var heightLerped: float
	var heightCurrent: float
	var heightHigh: float
	var heightLow: float
	
	# Width
	var widthLerped: float
	var widthCurrent: float
	var widthHigh: float
	var widthLow: float
	
	
