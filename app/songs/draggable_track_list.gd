class_name DraggableTrackList
extends VBoxContainer

# -----------------------------------------------------------------
# Drag & Drop Logic
# -----------------------------------------------------------------

# ------------- Only other draggable tracks can drop here -------------
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is DraggableTrack

# ------------- Data announced when a drop occurs -------------
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Emits a signal so the parent can handle the list order
	track_dropped.emit(data)

signal track_dropped(dropped_item: DraggableTrack)
