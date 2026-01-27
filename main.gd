extends Control

# Music Player
var playlistDirectory: String
var playlistIndex: int
var playlist: PackedStringArray
var shuffle: bool

# ------------- ------------- ------------- ------------- 
# Basic music controls
# ------------- ------------- ------------- ------------- 

# Plays the mp3 file at the provided path
func play_song_from_path(songPath: String) -> void:
	# Set new song to audio stream
	var stream = AudioStreamMP3.load_from_file(songPath)
	$NowPlaying.stream = stream
	
	# Create a new parser class and attach desired AudioStreamMP3
	var tagReader := MP3ID3Tag.new()
	tagReader.stream = stream
	
	# Update song info on screen
	$Layout/Player/TrackInfo/TrackName.text = tagReader.getTrackName()
	$Layout/Player/TrackInfo/TrackArtist.text = tagReader.getArtist()
	
	# Play the song
	$NowPlaying.play()
	set_play_pause_button()
	
# Constructs the full file path of the current song and plays it
func play_current_song() -> void:
	play_song_from_path(playlistDirectory + playlist[playlistIndex])

# Advances to the next song, then plays it
func play_next_song() -> void:
	if shuffle:
		playlistIndex = randi() % playlist.size()
	else:
		playlistIndex += 1
		if playlistIndex >= playlist.size():
			playlistIndex = 0
	play_current_song()

# When a song completes, play the next one
func _on_now_playing_finished() -> void:
	play_next_song()

# ------------- ------------- ------------- ------------- 
# Player Buttons (Left to right)
# ------------- ------------- ------------- ------------- 

# ------------- Shuffle -------------
func _on_shuffle_button_pressed() -> void:
	var shuffleButton = $Layout/Player/MusicControls/ShuffleButton
	shuffle = !shuffle
	if shuffle:
		shuffleButton.icon = preload("res://icons/shuffle.svg")
	else:
		shuffleButton.icon = preload("res://icons/ordered.svg")

# ------------- Step Back -------------
# Misleadingly named. Just restarts the current song. Shh don't tell anyone.
func _on_step_back_pressed() -> void:
	play_current_song()

# ------------- Play/Pause -------------
func _on_play_pause_button_pressed() -> void:
	$NowPlaying.stream_paused = !$NowPlaying.stream_paused
	set_play_pause_button()

func set_play_pause_button() -> void:
	var playButton = $Layout/Player/MusicControls/PlayPauseButton
	if $NowPlaying.stream_paused: 
		playButton.icon = preload("res://icons/play.svg")
	else: 
		playButton.icon = preload("res://icons/pause.svg")

# ------------- Step Forward -------------
func _on_step_forward_pressed() -> void:
	play_next_song()

# ------------- Volume -------------
func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)

# ------------- Open File -------------
func _on_open_song_button_pressed() -> void:
	$Layout/Player/MusicControls/SongFileDialog.visible = true

# Differentiates between m3u & mp3
func _on_song_file_dialog_file_selected(path: String) -> void:
	if path.ends_with(".mp3"):
		play_song_from_path(path)
	elif path.ends_with(".m3u"):
		open_playlist(path)
		play_current_song()

# Opens an m3u and stores the playlist in an array
  # ?? How big can the playlist get before this gets weird ??
func open_playlist(path: String) -> void:
	playlistDirectory = path.get_base_dir() + "/"
	var file = FileAccess.open(path, FileAccess.READ)
	var currentLine = file.get_csv_line("\n")
	while currentLine[0] != "":
		playlist.append(currentLine[0])
		currentLine = file.get_csv_line("\n")
	
# ------------- ------------- -------------
# Playlist Buttons (Top to bottom)
# ------------- ------------- -------------

# ------------- Playlist Directory -------------
func _on_playlist_directory_button_pressed() -> void:
	$Layout/Player/PlaylistControls/PlaylistDirectoryDialog.visible = true

# Opens a directory and displays all m3u playlists within (non-recursive)
func _on_playlist_directory_dialog_dir_selected(dir: String) -> void:
	var allPlaylists = $Layout/PrimaryWindow/PlaylistList
	allPlaylists.clear()
	var files = DirAccess.get_files_at(dir)
	for playlistFile in files:
		if playlistFile.ends_with(".m3u"):
			allPlaylists.add_item(playlistFile)

# Handles a playlist being selected or unselected
func _on_playlist_list_multi_selected(index: int, selected: bool) -> void:
	if !$NowPlaying.playing:
		return
	var fileName = $Layout/PrimaryWindow/PlaylistList.get_item_text(index)
	var file = FileAccess.open(playlistDirectory + "/" + fileName, FileAccess.READ_WRITE)
	var songFile = playlist[playlistIndex]
	if selected:
		print("SELECTED " + fileName)
		#file.store_csv_line(songFile, "\n")
	else:
		print("deselected " + fileName)
		var songIndex = file.get_as_text().find(songFile)
		print(songIndex)
