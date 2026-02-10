extends BoxContainer

# -----------------------------------------------------------------
# Presets
# -----------------------------------------------------------------

enum VISUALIZER_TYPES {
	BARS_THEME_FLAT,
	BARS_THEME,
	BARS_RAINBOW,
	BARS_PRISMATIC,
	AURORA_THEME,
	AURORA_PRISMATIC
}

const VISUALIZER_LABEL = {
	VISUALIZER_TYPES.BARS_THEME_FLAT: "Bars (Flat)",
	VISUALIZER_TYPES.BARS_THEME: "Bars (Theme)",
	VISUALIZER_TYPES.BARS_RAINBOW: "Bars (Rainbow)",
	VISUALIZER_TYPES.BARS_PRISMATIC: "Bars (Prismatic)",
	VISUALIZER_TYPES.AURORA_THEME: "Aurora (Theme)",
	VISUALIZER_TYPES.AURORA_PRISMATIC: "Aurora (Prismatic)",
}

const BAR_VISUALIZERS = [VISUALIZER_TYPES.BARS_THEME_FLAT, VISUALIZER_TYPES.BARS_THEME, VISUALIZER_TYPES.BARS_RAINBOW, VISUALIZER_TYPES.BARS_PRISMATIC]
const AURORA_VISUALIZERS = [VISUALIZER_TYPES.AURORA_THEME, VISUALIZER_TYPES.AURORA_PRISMATIC]
const RESPONSIVE_COLOR_VISUALIZERS = [VISUALIZER_TYPES.BARS_THEME, VISUALIZER_TYPES.BARS_PRISMATIC, VISUALIZER_TYPES.AURORA_THEME, VISUALIZER_TYPES.AURORA_PRISMATIC]

# -----------------------------------------------------------------
# Panel Setup
# -----------------------------------------------------------------

@onready var visualizer_select = $VisualizerControls/VisualizerSelect

var selected_visualizer = VISUALIZER_TYPES.AURORA_PRISMATIC
var visualizer_instance: Visualizer

func _ready() -> void:
	refresh_visualizer_select()
	refresh_visualizer()
	
# -----------------------------------------------------------------
# Visuals
# -----------------------------------------------------------------
	
func refresh_visualizer() -> void:
	if visualizer_instance:
		visualizer_instance.queue_free()
	
	if BAR_VISUALIZERS.has(selected_visualizer):
		visualizer_instance = Bars.new()
	else:
		visualizer_instance = Aurora.new()
	visualizer_instance.gradient = get_gradient_for_current()
	visualizer_instance.responsiveColorShift = RESPONSIVE_COLOR_VISUALIZERS.has(selected_visualizer)
	visualizer_instance.hue_shift = $VisualizerControls/ShiftSlider.value
	
	$VisualizerContainer.add_child(visualizer_instance)
	
	# -------------
	# Uncomment to overlay a test gradient on top of the visualizer to verify colors
	# -------------
	#var testGradient = GradientTexture2D.new()
	#testGradient.gradient = visualizer_instance.gradient
	#var gradientRect = TextureRect.new()
	#gradientRect.texture = testGradient
	#$VisualizerContainer.add_child(gradientRect)
	# -------------

func get_gradient_for_current() -> Gradient:
	var gradient: Gradient
	match selected_visualizer:
		VISUALIZER_TYPES.BARS_THEME_FLAT:
			gradient = theme_flat()
		VISUALIZER_TYPES.BARS_THEME, VISUALIZER_TYPES.AURORA_THEME:
			gradient = theme_gradient()
		VISUALIZER_TYPES.BARS_RAINBOW, VISUALIZER_TYPES.BARS_PRISMATIC, VISUALIZER_TYPES.AURORA_PRISMATIC:
			gradient = rainbow_gradient()
	return gradient

# ------------- Convenience Gradients --------------------------
func rainbow_gradient() -> Gradient:
	var gradient := Gradient.new()
	for index: int in visualizer_instance.element_count:
		var index_shifted_color = Color.from_hsv((
			# Gay math
			visualizer_instance.element_count * visualizer_instance.hue_shift + index) / visualizer_instance.element_count, 
			0.6, 
			0.7, 
			0.9
		)
		gradient.add_point(
			# Normalize to 0.0 - 1.0 range ?
			1.0/float(visualizer_instance.element_count + 1) + float(index)/float(visualizer_instance.element_count+ 1), 
			index_shifted_color
		)
	# Remove preset points
	gradient.remove_point(0)
	gradient.remove_point(0)
	return gradient

func theme_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0, Globals.themeColor.darkened(0.8))
	gradient.add_point(1, Globals.themeColor.lightened(0.2))
	# Remove preset points
	gradient.remove_point(0)
	gradient.remove_point(0)
	return gradient
	
func theme_flat() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0, Globals.themeColor)
	gradient.add_point(1, Globals.themeColor)
	# Remove preset points
	gradient.remove_point(0)
	gradient.remove_point(0)
	return gradient

# -----------------------------------------------------------------
# User Input
# -----------------------------------------------------------------

func _on_visualizer_select_item_selected(index: int) -> void:
	selected_visualizer = index as VISUALIZER_TYPES
	refresh_visualizer()

func refresh_visualizer_select() -> void:
	visualizer_select.clear()
	for index in VISUALIZER_LABEL.size():
		visualizer_select.add_item(VISUALIZER_LABEL[index], index)
	visualizer_select.select(VISUALIZER_TYPES.AURORA_PRISMATIC)

func _on_shift_slider_value_changed(value: float) -> void:
	visualizer_instance.hue_shift = value
	
func _on_resized() -> void:
	refresh_visualizer()
