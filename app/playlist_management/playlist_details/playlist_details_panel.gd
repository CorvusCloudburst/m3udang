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

# ------------- Play playlist in the player -------------
func _on_play_playlist_button_pressed() -> void:
	print("TODO: Play the playlist")
	#play_playlist.emit(filename) # Announces a playlist should play
	
func _open_panel(updated_filename: String) -> void:
	filename = updated_filename
	_refresh_contents()
	visible = true

func _refresh_contents() -> void:
	# Clear previouds contents
	draggable_track_list_panel.clear_panel_tracks()
	
	# Set the displayed playlist name
	var display_name = filename.get_file().rsplit(".", false, 1)[0] if filename else 'no playlist selected'
	playlist_name_label.text = display_name
	
	# Populate the tracks
	for track in get_playlist_tracks():
		draggable_track_list_panel.add_track(track)
	
# Get all the tracks in an m3u file
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
