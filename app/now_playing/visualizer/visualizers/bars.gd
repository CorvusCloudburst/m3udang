extends Visualizer2D

func _init() -> void:
	element_count = 64
	lerp_weight = 0.1
	
func _draw() -> void:
	for index: int in element_count:
		var bar_color: Color = get_color_for_index(index)
		var position_x = index * portioned_width
		var position_y = size.y - elements[index].heightLerped
		var bar_width = portioned_width - 1
		var bar_height = elements[index].heightLerped 
		
		var rectangle: Rect2 = Rect2(
			position_x,
			position_y,
			bar_width,
			bar_height
		)
		draw_rect(rectangle, bar_color)


	
