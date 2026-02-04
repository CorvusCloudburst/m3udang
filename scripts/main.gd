extends Control

var playlistDirectory: String
@onready var allPlaylists = $Layout/PrimaryWindow/PlaylistPanel/PlaylistDirectory

@onready var activePlaylist = $Layout/PrimaryWindow/SongPanel/SongList
var activePlaylistIndex: int
var shuffle: bool

func _ready() -> void:
	Globals.themeColor = Color.LIGHT_SLATE_GRAY

func _process(_delta) -> void:
	Globals.seconds = $NowPlaying.get_playback_position()

# -----------------------------------------------------------------
# Active Music Track
# -----------------------------------------------------------------

# Plays the mp3 file at the provided path
func play_song_at_path(relativePath: String) -> void:
	var absolutePath = playlistDirectory + relativePath
	
	# If the file doesn't exist, log it and skip it
	if !FileAccess.file_exists(absolutePath): 
		printerr("Song file doesn't exist: " + absolutePath)
		play_next_song()
		return
	
	# Set new song to audio stream
	var stream = AudioStreamMP3.load_from_file(absolutePath)
	$NowPlaying.stream = stream
	
	# Create a new parser class and attach desired AudioStreamMP3
	var tagReader := MP3ID3Tag.new()
	tagReader.stream = stream
	
	# Update song details in the player
	$Layout/Player/Controls/TrackInfo/TrackName.text = tagReader.getTrackName()
	$Layout/Player/Controls/TrackInfo/TrackArtist.text = tagReader.getArtist()
	Globals.songLength = stream.get_length()
	
	# Play the song
	$NowPlaying.play()
	set_play_pause_button()

# ---------------------------------------
# Sets the application state for the current song
func play_current_song() -> void:
	
	# Select the current song in the active playlist
	allPlaylists.deselect_all()
	activePlaylist.select(activePlaylistIndex)
	
	select_containing_playlists()
	activePlaylist.ensure_current_is_visible()
	
	# Play the song
	play_song_at_path(activePlaylist.get_item_text(activePlaylistIndex))

# ---------------------------------------
# Advances to the next song, then plays it
func play_next_song() -> void:
	if shuffle:
		activePlaylistIndex = randi() % activePlaylist.item_count
	else:
		activePlaylistIndex += 1
		if activePlaylistIndex >= activePlaylist.item_count:
			activePlaylistIndex = 0
	play_current_song()
	
# ---------------------------------------
# Plays the song at the specified index in the active playlist
func play_song_at_index(index: int) -> void:
		activePlaylistIndex = index
		play_current_song()
		
# ---------------------------------------
# When a song completes, play the next one
func _on_now_playing_finished() -> void:
	play_next_song()
	
# ---------------------------------------
# Stops the current song and clears the playlist
func clear_now_playing() -> void:
	activePlaylist.clear()
	activePlaylistIndex = 0
	$NowPlaying.stop()
	
# ---------------------------------------
# Toggles the play/pause icon depending on whether a song is playing
func set_play_pause_button() -> void:
	Globals.playing = !$NowPlaying.stream_paused
	# Toggle button icon to indicate current state
	var playButton = $Layout/Player/Controls/MusicControls/PlayPauseButton
	if $NowPlaying.stream_paused: 
		playButton.icon = preload("res://icons/play.svg")
	else: 
		playButton.icon = preload("res://icons/pause.svg")
	

# -----------------------------------------------------------------
# Playlist Directory
# -----------------------------------------------------------------

# ------------- New Playlist --------------------------
func _on_new_playlist_button_pressed() -> void:
	create_new_playlist()
	$Layout/PrimaryWindow/PlaylistPanel/NewPlaylistName.text = ""
	update_playlist_directory(playlistDirectory)

# ---------------------------------------
func create_new_playlist() -> FileAccess:
	# Playlist directory should already be set before making a new one
	if !playlistDirectory:
		printerr("No playlist directory selected yet.")
		return
	
	# Ensure the playlist is named validly
	var playlistName: String = $Layout/PrimaryWindow/PlaylistPanel/NewPlaylistName.text
	
	# Safety checks
	if playlistName.is_empty():
		printerr("No playlist name set.")
		return
	if !playlistName.ends_with(".m3u"):
		playlistName = playlistName + ".m3u"
	
	# Open the playlist file
	return FileAccess.open(playlistDirectory + playlistName, FileAccess.WRITE_READ)

# ------------- Generate Playlist --------------------------
func _on_generate_playlist_button_pressed() -> void:
	$Layout/Player/Controls/MusicControls/NewPlaylistFileDialog.visible = true

# ---------------------------------------
func _on_new_playlist_file_dialog_dir_selected(dir: String) -> void:
	var playlistFile = create_new_playlist()
	if !playlistDirectory:
		print("Whoops! No playlist directory selected.")
		return
	$Layout/PrimaryWindow/PlaylistPanel/NewPlaylistName.text = ""
	# Recursively traverse the directory to build the playlist
	traverseDirectory(dir, playlistFile)
	update_playlist_directory(playlistDirectory)

# ---------------------------------------
func traverseDirectory(dir: String, playlistFile: FileAccess) -> void:
	var files = DirAccess.get_files_at(dir)
	for file in files:
		if file.ends_with(".mp3"):
			playlistFile.store_line(dir + "/" + file)
	
	var directories = DirAccess.get_directories_at(dir)
	print(str(directories))
	for subdirectory in directories:
		traverseDirectory(dir + "/" + subdirectory, playlistFile)

# ------------- Playlist Directory --------------------------
# Opens a directory and displays all m3u playlists within (non-recursively)
func update_playlist_directory(dir: String) -> void:
	var files = DirAccess.get_files_at(dir)
	
	# Clear everything
	allPlaylists.clear()
	
	# Update the directory
	playlistDirectory = dir
	if !playlistDirectory.ends_with("/"):
		playlistDirectory = playlistDirectory + "/"
	
	# Populate the playlists
	for playlistFile in files:
		if playlistFile.ends_with(".m3u"):
			allPlaylists.add_item(playlistFile)
			
	select_containing_playlists()

# ---------------------------------------
# Handles a playlist being selected or unselected
func _on_playlist_list_multi_selected(index: int, selected: bool) -> void:
	# If there's no song playing, do nothing
	if !$NowPlaying.playing:
		return
		
	# Get the relative filepath of the currently playing song
	var songFile = activePlaylist.get_item_text(activePlaylistIndex)
	
	# Open the selected playlist
	var fileName = allPlaylists.get_item_text(index)
	var fullFileName = playlistDirectory + "/" + fileName
	var file = FileAccess.open(fullFileName, FileAccess.READ_WRITE)
	
	if selected:
		# Add the song to the end of the playlist
		print_verbose("SELECTED " + fileName)
		file.seek_end()
		file.store_line(songFile)
	else:
		# Find the song in the playlist and remove it
		print_verbose("deselected " + fileName)
		var file_song_removed = file.get_as_text().replace(songFile, "").replace("\n\n", "\n")
		
		# Rewrite the playlist file without the removed song
		var newFile = FileAccess.open(fullFileName, FileAccess.WRITE)
		newFile.store_string(file_song_removed)

# ---------------------------------------
# Highlight the playlists that contain the currently playing song
func select_containing_playlists() -> void:
	for index in allPlaylists.item_count:
		var playlistName = allPlaylists.get_item_text(index)
		var playlistFile = FileAccess.open(playlistDirectory + playlistName, FileAccess.READ)
		if playlistFile.get_as_text().contains(activePlaylist.get_item_text(activePlaylistIndex)):
			allPlaylists.select(index, false)

# -----------------------------------------------------------------
# Active Playlist
# -----------------------------------------------------------------

func _on_song_list_item_activated(index: int) -> void:
	play_song_at_index(index)


# -----------------------------------------------------------------
# Music Player Controls
# -----------------------------------------------------------------

# ------------- Time Slider --------------------------
func _on_time_slider_drag_started() -> void:
	$Layout/Player/TimeSlider.dragging = true
	
func _on_time_slider_drag_ended(value_changed: bool) -> void:
	var timeSlider = $Layout/Player/TimeSlider
	timeSlider.dragging = false
	if value_changed:
		$NowPlaying.seek(timeSlider.value)

# ------------- Open Playlist --------------------------
func _on_open_playlist_button_pressed() -> void:
	$Layout/Player/Controls/MusicControls/PlaylistFileDialog.visible = true

# ---------------------------------------
# Opens a playlist and plays a song
func _on_playlist_file_selected(path: String) -> void:
	if path.ends_with(".m3u"):
		open_playlist(path)
		if (shuffle):
			play_next_song() # Pick a random song
		else:
			play_current_song() # Start at index 0
	else:
		printerr("Selected file is not an .m3u")
		pass

# ---------------------------------------
# Opens an m3u and stores each relative path in an array to serve as the active playlist
  # ?? How big can the playlist get before this gets weird ??
func open_playlist(path: String) -> void:
	update_playlist_directory(path.get_base_dir() + "/")
	activePlaylist.clear()
	$Layout/PrimaryWindow/SongPanel/CurrentPlaylist.text = path.get_file()
	var file = FileAccess.open(path, FileAccess.READ)
	while !file.eof_reached():
		var currentLine = file.get_line()
		# Ignore comments and anything that isn't an m3u
		if !currentLine.begins_with("#") && currentLine.ends_with(".mp3"):
			activePlaylist.add_item(currentLine)

# ------------- Shuffle --------------------------
func _on_shuffle_button_pressed() -> void:
	var shuffleButton = $Layout/Player/Controls/MusicControls/ShuffleButton
	shuffle = !shuffle
	# Toggle button icon to indicate current state
	if shuffle:
		shuffleButton.icon = preload("res://icons/shuffle.svg")
	else:
		shuffleButton.icon = preload("res://icons/ordered.svg")

# ------------- Step Back --------------------------
# Misleadingly named. Just restarts the current song. Shh don't tell anyone.
func _on_step_back_pressed() -> void:
	play_current_song()

# ------------- Play/Pause --------------------------
func _on_play_pause_button_pressed() -> void:
	$NowPlaying.stream_paused = !$NowPlaying.stream_paused
	set_play_pause_button()

# ------------- Step Forward --------------------------
func _on_step_forward_pressed() -> void:
	play_next_song()

# ------------- Volume --------------------------
func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)

# ------------- Color --------------------------
func _on_color_button_pressed() -> void:
	var colorPicker = $Layout/Player/Controls/ColorButton/ColorPicker
	colorPicker.visible = !colorPicker.visible

func _on_color_picker_color_changed(color: Color) -> void:
	Globals.themeColor = color
	var dimmedColor = Color(color)
	dimmedColor.a = 0.5
	
	# Overlay
	$ColorOverlay.color = dimmedColor
	
	# Sliders
	$Layout/Player/TimeSlider.self_modulate = dimmedColor
	$Layout/Player/Controls/MusicControls/VolumeSlider.self_modulate = dimmedColor
	
	# Playlist Panel
	$Layout/PrimaryWindow/PlaylistPanel/NewPlaylistName.add_theme_color_override("font_color", color)
	$Layout/PrimaryWindow/PlaylistPanel/NewPlaylistName.add_theme_color_override("font_placeholder_color", dimmedColor)
	$Layout/PrimaryWindow/PlaylistPanel/NewPlaylistName/GeneratePlaylistButton.self_modulate = color
	$Layout/PrimaryWindow/PlaylistPanel/NewPlaylistName/NewPlaylistButton.self_modulate = color
	
	# Visualizer Menu
	$Layout/PrimaryWindow/VisualizerPanel/VisualizerControls/VisualizerSelect.add_theme_color_override("font_color", color)
	$Layout/PrimaryWindow/VisualizerPanel/VisualizerControls/ShiftSlider.self_modulate = dimmedColor
	
	# Song Panel
	$Layout/PrimaryWindow/SongPanel/CurrentPlaylist.add_theme_color_override("font_color", color)
	
	# Player
	$Layout/Player/Controls/MusicControls/OpenPlaylistButton.self_modulate = color
	$Layout/Player/Controls/MusicControls/ShuffleButton.self_modulate = color
	$Layout/Player/Controls/MusicControls/StepBack.self_modulate = color
	$Layout/Player/Controls/MusicControls/PlayPauseButton.self_modulate = color
	$Layout/Player/Controls/MusicControls/StepForward.self_modulate = color
	
	$Layout/Player/Controls/TrackInfo/TrackArtist.add_theme_color_override("font_color", color)
	$Layout/Player/Controls/TrackInfo/TrackName.add_theme_color_override("font_color", color)
	
	$Layout/Player/Controls/ColorButton.self_modulate = color
