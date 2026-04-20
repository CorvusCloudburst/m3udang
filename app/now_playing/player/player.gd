extends Control

@onready var track_player: AudioStreamPlayer = $TrackPlayer

# -----------------------------------------------------------------
# Active Track Functions
# -----------------------------------------------------------------
func play_track(relative_path: String) -> void:
	var absolute_filepath = Globals.playlist_directory + relative_path
	# If the file doesn't exist, log it and skip it
	if !FileAccess.file_exists(absolute_filepath): 
		printerr("Audio file doesn't exist: " + absolute_filepath)
		# TODO: Emit track ended event
		return
