class_name Bars
extends Visualizer

func _init() -> void:
	texture = preload("res://packaging/night-sky.png")
	element_count = 64
	lerp_weight = 0.1

func _draw():
	for index: int in element_count:
		var color: Color = responsive_color(index) if responsiveColorShift else static_color(index)
		var rectangle: Rect2 = Rect2(
			index * portioned_width,            	# Position X
			size.y - elements[index].heightLerped,  # Position Y
			portioned_width - 1,            		# Width
			elements[index].heightLerped            # Height
		)
		draw_rect(rectangle, color)
