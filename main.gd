extends Control

var playlistDirectory: String
@onready var allPlaylists = $Layout/PrimaryWindow/PlaylistDirectory

@onready var activePlaylist = $Layout/PrimaryWindow/SongList
var activePlaylistIndex: int
var shuffle: bool

# ------------- ------------- ------------- ------------- 
# Active Music Track
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
	activePlaylist.deselect_all()
	activePlaylist.select(activePlaylistIndex)
	play_song_from_path(playlistDirectory + activePlaylist.get_item_text(activePlaylistIndex))

# Advances to the next song, then plays it
func play_next_song() -> void:
	if shuffle:
		activePlaylistIndex = randi() % activePlaylist.item_count
	else:
		activePlaylistIndex += 1
		if activePlaylistIndex >= activePlaylist.item_count:
			activePlaylistIndex = 0
	play_current_song()

# Plays the song at the specified index in the active playlist
func play_song_at_index(index: int) -> void:
		activePlaylistIndex = index
		play_current_song()

# When a song completes, play the next one
func _on_now_playing_finished() -> void:
	play_next_song()

# Stops all playling and clears the playlist
func clear_now_playing() -> void:
	activePlaylist.clear()
	activePlaylistIndex = 0
	$NowPlaying.stop()

# ------------- ------------- ------------- ------------- 
# Playlist Directory
# ------------- ------------- ------------- ------------- 
# Opens a directory and displays all m3u playlists within (non-recursive)	
func update_playlist_directory(dir: String) -> void:
	var files = DirAccess.get_files_at(dir)
	
	allPlaylists.clear()
	clear_now_playing()
	playlistDirectory = dir + "/"
	
	for playlistFile in files:
		if playlistFile.ends_with(".m3u"):
			allPlaylists.add_item(playlistFile)

# Handles a playlist being selected or unselected
func _on_playlist_list_multi_selected(index: int, selected: bool) -> void:
	if !$NowPlaying.playing:
		return
	var fileName = allPlaylists.get_item_text(index)
	var file = FileAccess.open(playlistDirectory + "/" + fileName, FileAccess.READ_WRITE)
	var songFile = activePlaylist.get_item_text(activePlaylistIndex)
	if selected:
		print("SELECTED " + fileName)
		#file.store_csv_line(songFile, "\n")
	else:
		print("deselected " + fileName)
		var songIndex = file.get_as_text().find(songFile)
		print(songIndex)

	
# ------------- ------------- ------------- ------------- 
# Active Playlist
# ------------- ------------- ------------- ------------- 

func _on_song_list_item_activated(index: int) -> void:
	play_song_at_index(index)
	

# ------------- ------------- ------------- ------------- 
# Player Controls (Left to right)
# ------------- ------------- ------------- ------------- 

# ------------- Open Playlist -------------
func _on_open_playlist_button_pressed() -> void:
	$Layout/Player/MusicControls/PlaylistFileDialog.visible = true

# Differentiates between m3u & mp3
func _on_playlist_file_selected(path: String) -> void:
	if path.ends_with(".m3u"):
		open_playlist(path)
		play_current_song()
	else:
		printerr("Selected file is not an .m3u")
		pass

# Opens an m3u and stores the playlist in an array
  # ?? How big can the playlist get before this gets weird ??
func open_playlist(path: String) -> void:
	update_playlist_directory(path.get_base_dir() + "/")
	var file = FileAccess.open(path, FileAccess.READ)
	var currentLine = file.get_csv_line("\n")
	while currentLine[0] != "":
		activePlaylist.add_item(currentLine[0])
		currentLine = file.get_csv_line("\n")

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
