extends Panel

# Constants
const DRAGGABLE_TRACK_SCENE = preload("res://app/songs/draggable_track.tscn")

# Display elements
@onready var track_list: DraggableTrackList = $ScrollContainer/DraggableTrackList
@onready var scroll_container: ScrollContainer = $ScrollContainer

# -----------------------------------------------------------------
# External API
# -----------------------------------------------------------------

# ------------- Signals -------------
signal tracklist_modified()

# ------------- Object methods -------------
# Returns a list of of the songs contained within
func get_track_list() -> Array:
	var file_list: Array = []
	var track_items = track_list.get_children()
	for track in track_items:
		if track is DraggableTrack:
			file_list.append(track.track_file_path)
	return file_list
	
# Adds a new track to the list, supplied from elsewhere by filepath
func add_track(track_file_path: String) -> void:
	_insert_track_into_list(track_file_path)

# Clears all children
func clear_panel_tracks() -> void:
	for child in track_list.get_children():
		child.queue_free()

# Total tracks in the list
func get_track_count() -> int:
	return track_list.get_child_count()

# -----------------------------------------------------------------
# Display
# -----------------------------------------------------------------

func scroll_to(percent: float) -> void:
	var min_value = scroll_container.get_v_scroll_bar().min_value
	var max_value = scroll_container.get_v_scroll_bar().max_value
	var scrollTo = (max_value * percent) + min_value
	print("scrolling to: " + str(scrollTo) + " of " + str(scroll_container.get_v_scroll_bar().max_value))
	scroll_container.scroll_vertical = clamp(scrollTo as int - 30, min_value, max_value)

# -----------------------------------------------------------------
# Internal Track Management
# -----------------------------------------------------------------

# Adds a track to the list
func _insert_track_into_list(track_to_add: String, index: int = -1) -> void:
	var new_track = DRAGGABLE_TRACK_SCENE.instantiate()
	new_track.track_file_path = track_to_add
	
	# Adds the track to the list
	track_list.add_child(new_track)
	# Listen for drag and drop signals for this track
	new_track.connect("track_dropped", _on_draggable_track_dropped)
	new_track.connect("track_duplicated", _on_track_duplicated)
	new_track.connect("track_deleted", _on_track_deleted)
	# Moves the track to the provided index, if specified
	if index > -1:
		track_list.move_child(new_track, index)

# -----------------------------------------------------------------
# Drag & Drop
# -----------------------------------------------------------------

# Fires when a DraggableTrack is dropped onto the list
func _on_draggable_track_dropped(dropped_track: DraggableTrack, index: int) -> void:
	# If dragging from within the list, relocate
	if dropped_track.get_parent() == track_list:
		track_list.move_child(dropped_track, index)
	# If dragging from elsewhere, add a new copy so the old one remains unaffected
	else:
		_insert_track_into_list(dropped_track.track_file_path, index)
	tracklist_modified.emit()
	
# Insert the duplicated track beside its origin
func _on_track_duplicated(duplicated_track_file: String, index: int) -> void:
	_insert_track_into_list(duplicated_track_file, index)
	tracklist_modified.emit()
	
func _on_track_deleted(_deleted_track_file: String, _index: int) -> void:
	tracklist_modified.emit()

# A track is dropped on an unoccupied space in the list box
func _on_draggable_track_list_track_dropped(dropped_item: DraggableTrack) -> void:
	var ending_index = track_list.get_child_count()
	_on_draggable_track_dropped(dropped_item, ending_index)
	tracklist_modified.emit()
