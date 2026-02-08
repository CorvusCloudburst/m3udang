# Tutorial (Primary): https://www.youtube.com/watch?v=TFNfzf_H530
# Tutorial (Frequency math): https://www.youtube.com/watch?v=jttL809UdnQ

extends PanelContainer

# ---------------------------------------
# Spectrum Info
const FREQ_MAX: float = 11050.0
const MIN_DB: int = 60
var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance

@export var visualizerType: String
@export var shift: float

# Bar Visualizers
const RANGE_COUNT: int = 32
var spectrum: Array[SpectrumRange] = []
var bar_width: float = 0.0

# Reference gradients
var rainbow_gradient: Gradient = Gradient.new()

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
	draw_bars()
		
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


# ---------------------------------------
# Color Management
# ---------------------------------------

# -------------
func static_rainbow(index: int) -> Color:
	return Color.from_hsv((RANGE_COUNT * shift + index * 0.9) / RANGE_COUNT, 0.6, 0.7, 0.9)
	
# -------------
func dynamic_rainbow(index:int) -> Color:
	var shiftedValue = spectrum[index].energy + shift
	if shiftedValue > 1.0:
		shiftedValue = shiftedValue - 1.0
	return rainbow_gradient.sample(shiftedValue)
	
# -------------
func dynamic_theme(index:int) -> Color:
	var color = Globals.themeColor
	var minValue = min(Globals.themeColor.v, 0.2)
	var maxValue = max(Globals.themeColor.v, 0.35)
	color.v = clamp(spectrum[index].energy * 1.75, minValue, maxValue)
	return color

# ---------------------------------------
func _update_spectrum_data() -> void:
	for i: int in RANGE_COUNT:
		# Represented frequency range
		spectrum[i].hz_start = (i * FREQ_MAX) / RANGE_COUNT
		spectrum[i].hz_end = ((i + 1) * FREQ_MAX) / RANGE_COUNT
		
		# Fancy sound stuff
		spectrum[i].magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(spectrum[i].hz_start, spectrum[i].hz_end).length()
		spectrum[i].energy = clampf((MIN_DB + linear_to_db(spectrum[i].magnitude)) / MIN_DB, 0, 1)
		
		# Adjust relative height values
		spectrum[i].heightCurrent = spectrum[i].energy * size.y * 15.0
		if spectrum[i].heightCurrent > spectrum[i].heightHigh:
			spectrum[i].heightHigh = spectrum[i].heightCurrent
		else:
			spectrum[i].heightHigh = lerp(spectrum[i].heightHigh, spectrum[i].heightCurrent, 0.1)
		if spectrum[i].heightCurrent <= 0:
			spectrum[i].heightLow = lerp(spectrum[i].heightLow, spectrum[i].heightCurrent, 0.1)
		spectrum[i].heightLerped = lerp(spectrum[i].heightLow, spectrum[i].heightHigh, 0.1)
		
		# Adjust relative width values
		spectrum[i].widthCurrent = spectrum[i].energy * size.x * 10.0
		if spectrum[i].widthCurrent > spectrum[i].widthHigh:
			spectrum[i].widthHigh = spectrum[i].widthCurrent
		else:
			spectrum[i].widthHigh = lerp(spectrum[i].widthHigh, spectrum[i].widthCurrent, 0.1)
		if spectrum[i].widthCurrent <= 0:
			spectrum[i].widthLow = lerp(spectrum[i].widthLow, spectrum[i].widthCurrent, 0.1)
		spectrum[i].widthLerped = lerp(spectrum[i].widthLow, spectrum[i].widthHigh, 0.1)

# ---------------------------------------
func _on_resized() -> void:
	bar_width = size.x / RANGE_COUNT

# ---------------------------------------
class SpectrumRange:
	var hz_start: float
	var hz_end: float
	
	var magnitude: float
	var energy: float
	
	# Helpful visual values
	var heightLerped: float
	var heightCurrent: float
	var heightHigh: float
	var heightLow: float
	
	var widthLerped: float
	var widthCurrent: float
	var widthHigh: float
	var widthLow: float
