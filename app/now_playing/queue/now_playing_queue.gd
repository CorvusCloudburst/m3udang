extends Control

# Display elements
@onready var collapse_queue_button: Button = $QueuePanel/QueueLayout/QueueHeader/CollapseQueueButton
@onready var queue_details_layout: HBoxContainer = $QueuePanel/QueueLayout/QueueHeader/QueueDetailsLayout
@onready var track_count_label: Label = $QueuePanel/QueueLayout/QueueHeader/QueueDetailsLayout/TrackCountLabel
@onready var track_queue: Panel = $QueuePanel/QueueLayout/TrackQueue

# State
var open: bool = true

# -----------------------------------------------------------------
# Setup
# -----------------------------------------------------------------
func _ready() -> void:
	SignalBus.play_playlist.connect(queue_playlist)
	_update_track_count()

# -----------------------------------------------------------------
# External API
# -----------------------------------------------------------------
# Replaces the current queue with the provided playlist
func queue_playlist(filename: String) -> void:
	# Clear previous contents
	track_queue.clear_panel_tracks()
	
	var playlist_tracks = get_playlist_tracks(filename)
	
	# Populate the tracks
	for track in playlist_tracks:
		track_queue.add_track(track)
	
	# Update UI
	_update_track_count()
	
	# Play the first song
	SignalBus.play_track.emit(playlist_tracks[0])

# Returns relative paths of all the tracks in the provided list
func get_playlist_tracks(filename: String) -> Array:
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

func track_count() -> int:
	return track_queue.get_track_count()
	
func get_queued_tracks() -> Array:
	return track_queue.get_track_list()


# -----------------------------------------------------------------
# Display elements
# -----------------------------------------------------------------
# Updates the displayed track count
func _update_track_count() -> void:
	track_count_label.text = str(track_queue.get_track_count()) + " tracks"

# Collapse button
func _on_collapse_queue_button_pressed() -> void:
	open = !open
	collapse_queue_button.icon = preload("res://icons/stepForward.png") if open else preload("res://icons/stepBack.png")
	queue_details_layout.visible = open
	track_queue.visible = open
	custom_minimum_size = Vector2(300, 0) if open else Vector2(35, 0)

	
