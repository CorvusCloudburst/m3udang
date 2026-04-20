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
		_on_track_player_finished()
		return
	
	# Set new song to audio stream
	var stream = AudioStreamMP3.load_from_file(absolute_filepath)
	track_player.stream = stream
	
	# TODO: Get mp3 tags
	
	# Play the song
	$NowPlaying.play()
	# TODO: Toggle play/pause button

func _on_track_player_finished() -> void:
	SignalBus.track_finished.emit()
