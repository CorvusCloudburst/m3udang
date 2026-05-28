extends Panel

@onready var now_playing_queue: Control = $NowPlayingLayout/MainLayout/NowPlayingQueue
@onready var player: Control = $NowPlayingLayout/Player

# -----------------------------------------------------------------
# Setup
# -----------------------------------------------------------------

# Internal data
var current_track_index: int = 0

func _ready():
	SignalBus.track_finished.connect(_on_track_finished)
	

# -----------------------------------------------------------------
# Button Controls
# -----------------------------------------------------------------
func _on_player_step_back() -> void:
	pass # Replace with function body.

func _on_player_step_forward() -> void:
	play_next_song()

# Fired whenever the currently playing track ends
func _on_track_finished() -> void:
	play_next_song()
	
# -----------------------------------------------------------------
# Track Management
# -----------------------------------------------------------------

# Restarts the current song
func restart_song() -> void:
	player.restart_track()

# Plays the next song
func play_next_song() -> void:
	print("Playing next song. Shuffle is: " + str(player.shuffle))
	# Determine the index of the next track
	if player.shuffle:
		var total_tracks = now_playing_queue.track_count()
		current_track_index = randi_range(0, total_tracks - 1)
	else:
		current_track_index = current_track_index + 1
	play_song_at_index(current_track_index)

# Play the song at the specified index
func play_song_at_index(index: int) -> void: 
	print("Playing song at index: " + str(index))
	var track_list = now_playing_queue.get_queued_tracks()
	player.play_track(track_list[index])
	now_playing_queue.scroll_to_index(index)
