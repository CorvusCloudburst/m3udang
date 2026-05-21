extends Visualizer2D

# TODO: Opacity lerped by energy

func _init() -> void:
	lerp_weight = 0.05

func _draw():
	for index: int in element_count:
		var bar_color: Color = responsive_color(index)
		
		# Primary
		var color1 = Color(bar_color)
		color1.a = elements[index].energyLerped * 3.5
		var rectangle: Rect2 = Rect2(
			index * portioned_width - (portioned_width * 3),    # Position X
			0,  												# Position Y
			portioned_width * 6.25,            					# Width
			(elements[index].heightLerped) + (size.y/25)  # Height
		)
		draw_rect(rectangle, color1, true, -1.0,true)
		
		# Secondary
		var color2 = Color(bar_color)
		color2.a = elements[index].energyLerped * 1.5 if elements[index].energyLerped > 0.005 else 0.0
		var rectangle2: Rect2 = Rect2(
			index * portioned_width - (portioned_width * 3),    		# Position X
			0,  														# Position Y
			portioned_width * 7.2,            							# Width
			((elements[index].heightLerped * 2) + (size.y * 0.8)) / 2	# Height
		)
		draw_rect(rectangle2, color2, true, -1.0,true)
		
		# Tertiary
		var color3 = Color(bar_color)
		color3.a = elements[index].energyLerped / 2.0 if elements[index].energyLerped > 0.011 else 0.0
		var rectangle3: Rect2 = Rect2(
			index * portioned_width - (portioned_width * 3),    	# Position X
			0,  													# Position Y
			portioned_width * 10.3,            						# Width
			((elements[index].heightLerped * 3) + size.y) / 1.7 	# Height
		)
		draw_rect(rectangle3, color3, true, -1.0,true)
