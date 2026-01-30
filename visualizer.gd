# Tutorial (Primary): https://www.youtube.com/watch?v=TFNfzf_H530
# Tutorial (Frequency math): https://www.youtube.com/watch?v=jttL809UdnQ

extends PanelContainer

const BAR_COUNT: int = 32
const FREQ_MAX: float = 11050.0
const MIN_DB: int = 60

var spectrum: AudioEffectSpectrumAnalyzerInstance
var bars: Array[Height] = []
var bar_width: float = 0.0

func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0,0)
	_on_resized()
	for i: int in BAR_COUNT:
		bars.append(Height.new())
	
func _process(_delta: float) -> void:
	_update_spectrum_data()
	queue_redraw()
	
func _draw() -> void:
	for i: int in BAR_COUNT:
		var color: Color = Color.from_hsv((BAR_COUNT * 0.6 + i * 0.5) / BAR_COUNT, 0.4, 0.7, 0.7)
		var rectangle: Rect2 = Rect2(
			i * bar_width,            # Position X
			size.y - bars[i].actual,  # Position Y
			bar_width - 2,            # Width
			bars[i].actual            # Height
		)
		draw_rect(rectangle, color)
	
func _update_spectrum_data() -> void:
	for i: int in BAR_COUNT:
		# Determine the frequency range
		var hz_start = (i * FREQ_MAX) / BAR_COUNT
		var hz_end = ((i + 1) * FREQ_MAX) / BAR_COUNT
		
		# Determine the bar height
		var magnitude: float = spectrum.get_magnitude_for_frequency_range(hz_start, hz_end).length()
		var energy: float = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		var currentHeight: float = energy * size.y * 15.0
		
		# Adjust the height smoothly
		if currentHeight > bars[i].high:
			bars[i].high = currentHeight
		else:
			bars[i].high = lerp(bars[i].high, currentHeight, 0.1)
		if currentHeight <= 0:
			bars[i].low = lerp(bars[i].low, currentHeight, 0.1)
		
		# Apply the change
		bars[i].actual = lerp(bars[i].low, bars[i].high, 0.1)

func _on_resized() -> void:
	bar_width = size.x / BAR_COUNT
	print(size)
	print(size.x)

class Height:
	var high: float
	var low: float
	var actual: float
