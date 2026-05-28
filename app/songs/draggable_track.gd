class_name DraggableTrack
extends Panel

# -----------------------------------------------------------------
# Setup
# -----------------------------------------------------------------

# Display elements
@onready var track_label: Label = $MarginContainer/TrackLayout/TrackLabel

# Expected parameters
@export var track_file_path: String

func _ready() -> void:
	# Display pretty label
	var filename = track_file_path if track_file_path else 'track.mp3'
	track_label.text = filename.rsplit(".", false, 1)[0]
	tooltip_text = filename
	
# -----------------------------------------------------------------
# External API
# -----------------------------------------------------------------
signal track_duplicated(duplicatedTrack: String, index: int)
signal track_deleted(deletedTrack: String, index: int)
signal track_dropped(dropped_item: DraggableTrack, reference_index: int)
	
# -----------------------------------------------------------------
# Buttons
# -----------------------------------------------------------------

func _on_duplicate_button_pressed() -> void:
	track_duplicated.emit(track_file_path, get_index())
	
func _on_remove_button_pressed() -> void:
	get_parent().remove_child(self)
	track_deleted.emit(track_file_path, get_index())
	queue_free()

# -----------------------------------------------------------------
# Drag & Drop Logic
# -----------------------------------------------------------------

# ------------- The sprite while dragging -------------
func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview = duplicate()
	
	var preview_container = Control.new()
	preview.offset_left = -150
	preview.offset_top = -15
	preview_container.add_child(preview)

	set_drag_preview(preview_container)
	return self

# ------------- Allows dropping other tracks onto this one -------------
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is DraggableTrack

# ------------- Data announced when a track is dropped here -------------
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Emits a signal so the parent can handle the list order
	track_dropped.emit(data, get_index())
