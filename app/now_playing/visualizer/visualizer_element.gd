# A collection of useful values for generating visuals
class_name VisualizerElement

var hz_start: float
var hz_end: float
var magnitude: float

# Energy - Represents magnitude of this hz range on a 0.0 - 1.0 scale
var energyLerped: float
var energyCurrent: float
var energyHigh: float
var energyLow: float

# Height (relative to magnitude & parent height)
var heightLerped: float
var heightCurrent: float
var heightHigh: float
var heightLow: float

# Width (relative to magnitude & parent width)
var widthLerped: float
var widthCurrent: float
var widthHigh: float
var widthLow: float

# Useful constants I probably won't touch much
const FREQ_MAX: float = 11050.0
const MIN_DB: int = 60

# Updates the element's values using fancy music math
func update_values(
	spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance, # The audio 
	index: int,                                             # Index of this range
	total_elements: int,                                    # Total number of VisualizerElements
	lerp_weight: float,                                     # Determines how fast / smooth it moves
	x_modifier: float,                                      # Width to base math on
	y_modifier: float                                       # Height to base math on
):	
	# Update represented frequency range
	hz_start = (index * FREQ_MAX) / total_elements
	hz_end = ((index + 1) * FREQ_MAX) / total_elements
	magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(hz_start, hz_end).length()
	
	# Adjust energy values
	energyCurrent = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
	if energyCurrent > energyHigh:
		energyHigh = energyCurrent
	else:
		energyHigh = lerp(energyHigh, energyCurrent, lerp_weight)
	if energyCurrent <= 0:
		energyLow = lerp(energyLow, energyCurrent, lerp_weight)
	energyLerped = lerp(energyLow, energyHigh, lerp_weight)
	
	# Adjust relative height values
	heightCurrent = energyCurrent * y_modifier
	if heightCurrent > heightHigh:
		heightHigh = heightCurrent
	else:
		heightHigh = lerp(heightHigh, heightCurrent, lerp_weight)
	if heightCurrent <= 0:
		heightLow = lerp(heightLow, heightCurrent, lerp_weight)
	heightLerped = lerp(heightLow, heightHigh, lerp_weight)
	
	# Adjust relative width values
	widthCurrent = energyCurrent * x_modifier
	if widthCurrent > widthHigh:
		widthHigh = widthCurrent
	else:
		widthHigh = lerp(widthHigh, widthCurrent, lerp_weight)
	if widthCurrent <= 0:
		widthLow = lerp(widthLow, widthCurrent, lerp_weight)
	widthLerped = lerp(widthLow, widthHigh, lerp_weight)
