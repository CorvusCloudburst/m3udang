extends Node

@warning_ignore("unused_signal")
signal open_playlist_detail(playlist_file: String)

@warning_ignore("unused_signal")
signal play_playlist(playlist_file: String)

@warning_ignore("unused_signal")
signal play_track(relative_path: String)

@warning_ignore("unused_signal")
signal track_finished()

@warning_ignore("unused_signal")
signal playing_toggled(now_playing: bool)
