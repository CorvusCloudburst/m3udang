class_name VisualizerColors

enum ColorMode {
	FLAT,
	STATIC,
	MONO,
	RAINBOW,
	PRISMATIC
}

static var ColorModeLabels = {
	ColorMode.FLAT: "Flat",
	ColorMode.STATIC: "Static",
	ColorMode.MONO: "Mono",
	ColorMode.RAINBOW: "Rainbow",
	ColorMode.PRISMATIC: "Prismatic",
}

# ------------- Convenience Gradients --------------------------
static func get_gradient_for_color_mode(colorMode: ColorMode, color: Color, element_count: int, hue_shift: float = 0.0) -> Gradient:
	match colorMode:
		VisualizerColors.ColorMode.FLAT: return flat_gradient(color)
		VisualizerColors.ColorMode.STATIC, VisualizerColors.ColorMode.MONO: return mono_gradient(color)
		_: return rainbow_gradient(element_count, hue_shift)
	
static func rainbow_gradient(element_count: int, hue_shift: float) -> Gradient:
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

static func mono_gradient(color: Color) -> Gradient:
	var new_gradient = Gradient.new()
	new_gradient.add_point(0, color.darkened(0.8))
	new_gradient.add_point(1, color.lightened(0.2))
	# Remove preset points
	new_gradient.remove_point(0)
	new_gradient.remove_point(0)
	return new_gradient
	
static func flat_gradient(color: Color) -> Gradient:
	var new_gradient = Gradient.new()
	new_gradient.add_point(0, color)
	new_gradient.add_point(1, color)
	# Remove preset points
	new_gradient.remove_point(0)
	new_gradient.remove_point(0)
	return new_gradient
