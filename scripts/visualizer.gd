# Tutorial (Primary): https://www.youtube.com/watch?v=TFNfzf_H530
# Tutorial (Frequency math): https://www.youtube.com/watch?v=jttL809UdnQ

extends PanelContainer

# ---------------------------------------
# Spectrum Info
const FREQ_MAX: float = 11050.0
const MIN_DB: int = 60
var spectrum: AudioEffectSpectrumAnalyzerInstance

@export var visualizerType: String
@export var shift: float

# Bar Visualizers
const BAR_COUNT: int = 32
var bars: Array[Bar] = []
var bar_width: float = 0.0

# Reference gradients
var rainbow_gradient: Gradient = Gradient.new()

# ---------------------------------------
func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0,0)
	_on_resized()
	for i: int in BAR_COUNT:
		bars.append(Bar.new())
		rainbow_gradient.add_point(1.0/float(BAR_COUNT + 1) + float(i)/float(BAR_COUNT + 1), static_rainbow(i))
	rainbow_gradient.add_point(1, static_rainbow(0))
	rainbow_gradient.remove_point(0)

# ---------------------------------------
func _process(_delta: float) -> void:
	if Globals.playing:
		_update_spectrum_data()
		queue_redraw()

# ---------------------------------------
func _draw() -> void:
	draw_bars()
		
# ------------- Bars --------------------------
func draw_bars() -> void:
	for i: int in BAR_COUNT:
		
		var color: Color
		match visualizerType:
			"Bars (Static Rainbow)": color = static_rainbow(i)
			"Bars (Dynamic Rainbow)": color = dynamic_rainbow(i)
			"Bars (Dynamic Theme)": color = dynamic_theme(i)
			_: color = Globals.themeColor
				
		var rectangle: Rect2 = Rect2(
			i * bar_width,            # Position X
			size.y - bars[i].actual,  # Position Y
			bar_width - 2,            # Width
			bars[i].actual            # Height
		)
		draw_rect(rectangle, color)

# -------------
func static_rainbow(index: int) -> Color:
	return Color.from_hsv((BAR_COUNT * shift + index * 0.9) / BAR_COUNT, 0.6, 0.7, 0.9)
	
# -------------
func dynamic_rainbow(index:int) -> Color:
	var shiftedValue = bars[index].energy + shift
	if shiftedValue > 1.0:
		shiftedValue = shiftedValue - 1.0
	return rainbow_gradient.sample(shiftedValue)
	
# -------------
func dynamic_theme(index:int) -> Color:
	var color = Globals.themeColor
	var minValue = min(Globals.themeColor.v, 0.2)
	var maxValue = max(Globals.themeColor.v, 0.35)
	color.v = clamp(bars[index].energy * 1.75, minValue, maxValue)
	return color

# ---------------------------------------
func _update_spectrum_data() -> void:
	for i: int in BAR_COUNT:
		# Determine the frequency range
		bars[i].hz_start = (i * FREQ_MAX) / BAR_COUNT
		bars[i].hz_end = ((i + 1) * FREQ_MAX) / BAR_COUNT
		
		# Determine the bar height
		bars[i].magnitude = spectrum.get_magnitude_for_frequency_range(bars[i].hz_start, bars[i].hz_end).length()
		bars[i].energy = clampf((MIN_DB + linear_to_db(bars[i].magnitude)) / MIN_DB, 0, 1)
		bars[i].currentHeight = bars[i].energy * size.y * 15.0
		
		# Adjust the height smoothly
		if bars[i].currentHeight > bars[i].high:
			bars[i].high = bars[i].currentHeight
		else:
			bars[i].high = lerp(bars[i].high, bars[i].currentHeight, 0.1)
		if bars[i].currentHeight <= 0:
			bars[i].low = lerp(bars[i].low, bars[i].currentHeight, 0.1)
		
		# Apply the change
		bars[i].actual = lerp(bars[i].low, bars[i].high, 0.1)

# ---------------------------------------
func _on_resized() -> void:
	bar_width = size.x / BAR_COUNT

# ---------------------------------------
class Bar:
	var high: float
	var low: float
	var actual: float
	
	var hz_start: float
	var hz_end: float
	
	var magnitude: float
	var energy: float
	var currentHeight: float
