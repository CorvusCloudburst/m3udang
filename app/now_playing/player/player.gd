extends Control

# -----------------------------------------------------------------
# Setup
# -----------------------------------------------------------------
enum Repeat { NONE, ALL, ONE }

# Stream
@onready var track_player: AudioStreamPlayer = $TrackPlayer

# Controls
@onready var shuffle_button: Button = $PlayerPanel/OuterMargins/PlayerPanelLayout/PlayerControlsLayout/ControlsLayout/ShuffleButton
@onready var step_back_button: Button = $PlayerPanel/OuterMargins/PlayerPanelLayout/PlayerControlsLayout/ControlsLayout/StepBackButton
@onready var play_pause_button: Button = $PlayerPanel/OuterMargins/PlayerPanelLayout/PlayerControlsLayout/ControlsLayout/PlayPauseButton
@onready var step_forward_button: Button = $PlayerPanel/OuterMargins/PlayerPanelLayout/PlayerControlsLayout/ControlsLayout/StepForwardButton
@onready var repeat_button: Button = $PlayerPanel/OuterMargins/PlayerPanelLayout/PlayerControlsLayout/ControlsLayout/RepeatButton
@onready var timeline_slider: HSlider = $PlayerPanel/OuterMargins/PlayerPanelLayout/TimelineMargins/TimelineLayout/TimelineSlider

# Display
@onready var track_name_label: Label = $PlayerPanel/OuterMargins/PlayerPanelLayout/PlayerControlsLayout/TrackInfoLayout/TrackNameLabel
@onready var artist_label: Label = $PlayerPanel/OuterMargins/PlayerPanelLayout/PlayerControlsLayout/TrackInfoLayout/TrackMetadataLayout/ArtistLabel
@onready var album_label: Label = $PlayerPanel/OuterMargins/PlayerPanelLayout/PlayerControlsLayout/TrackInfoLayout/TrackMetadataLayout/AlbumLabel

# State
@export var shuffle: bool = true
@export var repeat: Repeat = Repeat.NONE
var track_length: float
var dragging: bool = false

func _ready() -> void:
	SignalBus.play_track.connect(play_track)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Player"), 0.5)
	
func _process(_delta: float) -> void:
	if !dragging:
		timeline_slider.value = track_player.get_playback_position()

# -----------------------------------------------------------------
# Active Track Functions
# -----------------------------------------------------------------
func restart_track() -> void:
	track_player.seek(0)

func play_track(relative_path: String) -> void:
	if (!relative_path):
		return
		
	var absolute_filepath = Globals.playlist_directory + relative_path
	
	# If the file doesn't exist, log it and skip it
	if !FileAccess.file_exists(absolute_filepath): 
		printerr("Audio file doesn't exist: " + absolute_filepath)
		_on_track_player_finished()
		return
	
	# Set new song to audio stream
	print("Playing song at: " + absolute_filepath)
	var stream = AudioStreamMP3.load_from_file(absolute_filepath)
	track_player.stream = stream
	
	# Get mp3 tags
	var tagReader := MP3ID3Tag.new()
	tagReader.stream = stream
	
	# Update song details
	track_name_label.text = tagReader.getTrackName()
	artist_label.text = tagReader.getArtist()
	album_label.text = tagReader.getAlbum()
	track_length = stream.get_length()
	
	# Play the song
	track_player.play()
	_toggle_play_pause_button_icon()
	
	# Update the time slider
	timeline_slider.min_value = 0
	timeline_slider.max_value = stream.get_length()

func _on_track_player_finished() -> void:
	SignalBus.track_finished.emit()


# -----------------------------------------------------------------
# Buttons / Interactivity
# -----------------------------------------------------------------

# ------------- Timeline -------------
func _on_timeline_slider_drag_started() -> void:
	dragging = true
	
func _on_timeline_slider_drag_ended(value_changed: bool) -> void:
	dragging = false
	if (value_changed):
		track_player.seek(timeline_slider.value)

# ------------- Shuffle -------------
# Shuffle Button
func _on_shuffle_button_pressed() -> void:
	shuffle = !shuffle
	_toggle_shuffle_button_icon()
	print("shuffle is: " + str(shuffle))

# Toggle button icon
func _toggle_shuffle_button_icon() -> void:
	if shuffle:
		shuffle_button.icon = preload("res://icons/shuffle.png")
	else:
		shuffle_button.icon = preload("res://icons/ordered.png")
	
# ------------- Step Back / Restart -------------
signal step_back()

func _on_step_back_button_pressed() -> void:
	track_player.seek(0)
	step_back.emit()

# ------------- Play/Pause -------------
# Play/Pause Button
func _on_play_pause_button_pressed() -> void:
	track_player.stream_paused = !track_player.stream_paused
	_toggle_play_pause_button_icon()
	SignalBus.playing_toggled.emit(!track_player.stream_paused)
	
# Toggle button icon
func _toggle_play_pause_button_icon() -> void:
	if track_player.playing:
		play_pause_button.icon = preload("res://icons/pause.png")
	else:
		play_pause_button.icon = preload("res://icons/play.png")
	
# ------------- Step Forward / Next track -------------
signal step_forward()

func _on_step_forward_button_pressed() -> void:
	step_forward.emit()

# ------------- Repeat -------------
func _on_repeat_button_pressed() -> void:
	repeat = (repeat as int + 1) % 3 as Repeat
	_toggle_repeat_button_icon()
	
func _toggle_repeat_button_icon() -> void:
	match repeat:
		Repeat.NONE:
			repeat_button.icon = preload("res://icons/no-repeat.png")
		Repeat.ALL:
			repeat_button.icon = preload("res://icons/repeat-all.png")
		Repeat.ONE:
			repeat_button.icon = preload("res://icons/repeat-1.png")

# ------------- Volume -------------
func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Player"), value)
