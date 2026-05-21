extends Panel

# -----------------------------------------------------------------
# Setup 
# -----------------------------------------------------------------
# Internal data
@export var filename: String # Should be provided by caller

# Display elements
@onready var playlist_name_label: Label = $PlaylistDetailsLayout/HeaderMargins/PlaylistDetailsPanelHeader/PlaylistNameLabel
@onready var draggable_track_list_panel: Panel = $PlaylistDetailsLayout/DraggableTrackListPanel

func _ready() -> void:
	# Listen for signals to open a playlist
	SignalBus.open_playlist_detail.connect(_open_panel)
	# Get fresh visuals
	_refresh_contents()

# -----------------------------------------------------------------
# Interactivity 
# -----------------------------------------------------------------

# ------------- Close playlist details -------------
func _on_close_playlist_details_button_pressed() -> void:
	visible = false
	
# ------------- Fires when the internal tracklist has been modified -------------
func _on_draggable_track_list_tracklist_modified() -> void:
	_save_playlist_to_file()

# ------------- Play playlist in the player -------------
func _on_play_playlist_button_pressed() -> void:
	SignalBus.play_playlist.emit(filename)
	SignalBus.playing_toggled.emit(true)

# ------------- Helpers -------------
# Opens the panel with fresh data
func _open_panel(updated_filename: String) -> void:
	filename = updated_filename
	_refresh_contents()
	visible = true

# Refreshes the UI contents of the playlist
func _refresh_contents() -> void:
	# Clear previous contents
	draggable_track_list_panel.clear_panel_tracks()
	
	# Set the displayed playlist name
	var display_name = filename.get_file().rsplit(".", false, 1)[0] if filename else 'no playlist selected'
	playlist_name_label.text = display_name
	
	# Populate the tracks
	for track in get_playlist_tracks():
		draggable_track_list_panel.add_track(track)
	
# Returns all the tracks in the m3u file
func get_playlist_tracks() -> Array:
	if !FileAccess.file_exists(Globals.playlist_directory + filename):
		return []
	
	var playlist_file = FileAccess.open(Globals.playlist_directory + filename, FileAccess.READ)
	var playlist_contents = []
	while !playlist_file.eof_reached():
		var current_line = playlist_file.get_line()
		# Ignore comments and anything that isn't an mp3
		if !current_line.begins_with("#") && current_line.ends_with(".mp3"):
			playlist_contents.append(current_line)
	return playlist_contents
	

# -----------------------------------------------------------------
# File Management
# -----------------------------------------------------------------

# Overwrites the playlist file with the currently saved song ordering
func _save_playlist_to_file() -> void:
	# Open the file
	var full_file_path = Globals.playlist_directory + filename
	var file = FileAccess.open(full_file_path, FileAccess.WRITE) # Overwrites previous content
	
	# Store each track in order
	for track in draggable_track_list_panel.get_track_list():
		file.store_line(track)
	
