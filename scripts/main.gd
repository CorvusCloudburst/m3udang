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
	$Layout/Player/Controls/TrackInfo/LowerRow/TrackArtist.text = tagReader.getArtist()
	$Layout/Player/Controls/TrackInfo/LowerRow/TrackAlbum.text = tagReader.getAlbum()
	Globals.songLength = stream.get_length()
	
	# Play the song
	$NowPlaying.play()
	set_play_pause_button()

# ---------------------------------------
# Sets the application state for the current song
func play_current_song() -> void:
	# Select and scroll to the playing song in the right side panel
	activePlaylist.select(activePlaylistIndex)
	activePlaylist.ensure_current_is_visible()
	
	# Highlight all playlists containing current song in left side panel
	allPlaylists.deselect_all()
	select_containing_playlists()
	
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
		playButton.icon = preload("res://icons/play.png")
	else: 
		playButton.icon = preload("res://icons/pause.png")
	

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
	# Playlist directory should already be set before making a new playlist
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
		printerr("Whoops! No playlist directory selected.")
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
# Handles a playlist being selected or unselected (adding/removing playing song from the playlist)
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
		file.seek_end()
		file.store_line(songFile)
	else:
		# Find the song in the playlist and remove it
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

# ------------- Non-Active Playlist Panel --------------------------
# Handles a playlist being clicked on (mostly relevant for capturing right clicking)
func _on_playlist_directory_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	# Limit logic to right-click
	if (mouse_button_index != 2): 
		return
	
	var playlistContentsPanel = $Layout/PrimaryWindow/PlaylistContentsPanel
	var playlistContents = $Layout/PrimaryWindow/PlaylistContentsPanel/PlaylistContents
	var playlistNameLabel = $Layout/PrimaryWindow/PlaylistContentsPanel/PlaylistContentsHeader/PlaylistContentsName
	
	# Toggle the panel visibility
	playlistContentsPanel.visible = true
	playlistContents.clear()
	
	# If visible, populate panel with contents of the playlist
	if playlistContentsPanel.visible: 
		# Open the selected playlist
		var playlistName = allPlaylists.get_item_text(index)
		var playlistContentsList = get_playlist_tracks(playlistName)
		
		playlistNameLabel.text = playlistName
		
		# List the playlist contents as list items in the panel
		for songFile in playlistContentsList:
			playlistContents.add_item(songFile)
			
		$Layout/PrimaryWindow/PlaylistContentsPanel/PlaylistContentsHeader/TrackCount.text = str(playlistContentsList.size()) + " tracks"
	
# ---------------------------------------
# Get all the tracks in an m3u file
func get_playlist_tracks(playlistName: String) -> Array:
	var playlistFile = FileAccess.open(playlistDirectory + playlistName, FileAccess.READ)
	var playlistContents = []
	while !playlistFile.eof_reached():
		var currentLine = playlistFile.get_line()
		# Ignore comments and anything that isn't an mp3
		if !currentLine.begins_with("#") && currentLine.ends_with(".mp3"):
			playlistContents.append(currentLine)
	return playlistContents
	
	

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
# Opens the m3u and populates the active playlist with its content
  # ?? How big can the playlist get before this gets weird ??
func open_playlist(path: String) -> void:
	update_playlist_directory(path.get_base_dir() + "/")
	activePlaylist.clear()
	$Layout/PrimaryWindow/SongPanel/PlaylistDetails/CurrentPlaylist.text = path.get_file()
	var file = FileAccess.open(path, FileAccess.READ)
	while !file.eof_reached():
		var currentLine = file.get_line()
		# Ignore comments and anything that isn't an mp3
		if !currentLine.begins_with("#") && currentLine.ends_with(".mp3"):
			activePlaylist.add_item(currentLine)
	$Layout/PrimaryWindow/SongPanel/PlaylistDetails/TotalTracks.text = str(activePlaylist.item_count) + ' tracks'

# ------------- Shuffle --------------------------
func _on_shuffle_button_pressed() -> void:
	var shuffleButton = $Layout/Player/Controls/MusicControls/ShuffleButton
	shuffle = !shuffle
	# Toggle button icon to indicate current state
	if shuffle:
		shuffleButton.icon = preload("res://icons/shuffle.png")
	else:
		shuffleButton.icon = preload("res://icons/ordered.png")

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
	
	# Visualizer
	$Layout/PrimaryWindow/VisualizerPanel/VisualizerControls/VisualizerSelect.add_theme_color_override("font_color", color)
	$Layout/PrimaryWindow/VisualizerPanel/VisualizerControls/ShiftSlider.self_modulate = dimmedColor
	$Layout/PrimaryWindow/VisualizerPanel.refresh_visualizer()
	
	# Song Panel
	$Layout/PrimaryWindow/SongPanel/PlaylistDetails/CurrentPlaylist.add_theme_color_override("font_color", color)
	$Layout/PrimaryWindow/SongPanel/PlaylistDetails/Divider/DividerImage.self_modulate = color
	$Layout/PrimaryWindow/SongPanel/PlaylistDetails/TotalTracks.add_theme_color_override("font_color", color)
	
	# Player
	$Layout/Player/Controls/MusicControls/OpenPlaylistButton.self_modulate = color
	$Layout/Player/Controls/MusicControls/ShuffleButton.self_modulate = color
	$Layout/Player/Controls/MusicControls/StepBack.self_modulate = color
	$Layout/Player/Controls/MusicControls/PlayPauseButton.self_modulate = color
	$Layout/Player/Controls/MusicControls/StepForward.self_modulate = color
	
	$Layout/Player/Controls/TrackInfo/TrackName.add_theme_color_override("font_color", color)
	$Layout/Player/Controls/TrackInfo/LowerRow/TrackArtist.add_theme_color_override("font_color", color)
	$Layout/Player/Controls/TrackInfo/LowerRow/Divider/DividerImage.self_modulate = color
	$Layout/Player/Controls/TrackInfo/LowerRow/TrackAlbum.add_theme_color_override("font_color", color)
	
	$Layout/Player/Controls/ColorButton.self_modulate = color


func _on_close_playlist_pressed() -> void:
	$Layout/PrimaryWindow/PlaylistContentsPanel.visible = false

func _on_play_this_playlist_pressed() -> void:
	var fullPlaylistPath = playlistDirectory + $Layout/PrimaryWindow/PlaylistContentsPanel/PlaylistContentsHeader/PlaylistContentsName.text
	_on_playlist_file_selected(fullPlaylistPath)
