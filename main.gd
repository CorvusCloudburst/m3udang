extends Control

var playlistDirectory: String
var playlistIndex: int
var playlist: PackedStringArray
var shuffle: bool
	
func _on_song_file_dialog_file_selected(path: String) -> void:
	if path.ends_with(".mp3"):
		play_song_from_path(path)
	elif path.ends_with(".m3u"):
		open_playlist(path)
		play_current_song()
		
func open_playlist(path: String) -> void:
	playlistDirectory = path.get_base_dir() + "/"
	var file = FileAccess.open(path, FileAccess.READ)
	var currentLine = file.get_csv_line("\n")
	while currentLine[0] != "":
		playlist.append(currentLine[0])
		currentLine = file.get_csv_line("\n")
		
func _on_open_song_button_pressed() -> void:
	$SongFileDialog.visible = true

func _on_play_pause_button_pressed() -> void:
	$NowPlaying.stream_paused = !$NowPlaying.stream_paused
	set_play_pause_button()
		
func set_play_pause_button() -> void:
	var playButton = $Player/MusicControls/PlayPauseButton
	if $NowPlaying.stream_paused: 
		playButton.icon = preload("res://icons/play.svg")
	else: 
		playButton.icon = preload("res://icons/pause.svg")

func _on_shuffle_button_pressed() -> void:
	var shuffleButton = $Player/MusicControls/ShuffleButton
	shuffle = !shuffle
	if shuffle:
		shuffleButton.icon = preload("res://icons/shuffle.svg")
	else:
		shuffleButton.icon = preload("res://icons/ordered.svg")

func _on_step_back_pressed() -> void:
	play_current_song()

func _on_step_forward_pressed() -> void:
	play_next_song()
		
func _on_now_playing_finished() -> void:
	play_next_song()
	
func play_next_song() -> void:
	if shuffle:
		playlistIndex = randi() % playlist.size()
	else:
		playlistIndex += 1
		if playlistIndex >= playlist.size():
			playlistIndex = 0
	play_current_song()
	
func play_current_song() -> void:
	play_song_from_path(playlistDirectory + playlist[playlistIndex])

func play_song_from_path(songPath: String) -> void:
	# Set new song to audio stream
	var stream = AudioStreamMP3.load_from_file(songPath)
	$NowPlaying.stream = stream
	
	#Create a new parser class and attach desired AudioStreamMP3
	var tagReader := MP3ID3Tag.new()
	tagReader.stream = stream
	
	# Update song info on screen
	$Player/TrackInfo/TrackName.text = tagReader.getTrackName()
	$Player/TrackInfo/TrackArtist.text = tagReader.getArtist()
	
	# Play the song
	$NowPlaying.play()
	set_play_pause_button()
