extends Panel

# Constants
const LIST_ITEM_SCENE = preload("res://app/playlist_management/playlist_list_item.tscn")

# Display Elements
@onready var playlist_directory_label: Label = $PlaylistBrowser/HeaderOuterMargins/PlaylistPanelHeader/PlaylistDirectoryLabel
@onready var playlist_list: VBoxContainer = $PlaylistBrowser/PlaylistBrowserPanel/ScrollContainer/OuterMargins/PlaylistList

# Internal Data
@export var playlists: Array

# -----------------------------------------------------------------
# Playlist Directory File Dialog
# -----------------------------------------------------------------
func _on_change_directory_button_pressed() -> void:
	$PlaylistDirectoryDialog.visible = true

func _on_playlist_directory_dialog_dir_selected(dir: String) -> void:
	var selected_directory = dir
	
	# Ensure the directory ends with a slash
	if !selected_directory.ends_with("/"):
		selected_directory = selected_directory + "/"
	
	# Set the playlist directory
	Globals.playlist_directory = selected_directory
	
	# Update the directory label with the directory name
	playlist_directory_label.text = selected_directory.get_base_dir().rsplit("/", false, 1)[1]
	playlist_directory_label.tooltip_text = dir
	
	refresh_playlists()
	$NewPlaylistDialog.root_subfolder = Globals.playlist_directory
	
# -----------------------------------------------------------------
# New Playlist Dialog
# -----------------------------------------------------------------
func _on_new_playlist_button_pressed() -> void:
	$NewPlaylistDialog.visible = true
	
func _on_new_playlist_dialog_file_selected(path: String) -> void:
	var new_playlist_file = path
	
	# Safety checks
	if !new_playlist_file.ends_with(".m3u"):
		new_playlist_file = new_playlist_file + ".m3u"
		
	# Open the playlist file to create it
	FileAccess.open(new_playlist_file, FileAccess.WRITE_READ)
	
	# Refresh the UI
	refresh_playlists()
	
	# Open the new playlist details
	# TODO: Find new playlist item by the filename and tell it to emit an open-details signal

# -----------------------------------------------------------------
# Playlist Browser
# -----------------------------------------------------------------

# ------------- Refresh the playlists -------------
func refresh_playlists() -> void:
	update_playlist_data()
	update_playlist_browser()

# ------------- Update internal data -------------
func update_playlist_data() -> void:
	# Clear any old data
	playlists.clear()
	
	# Get the files in the current directory
	var files = DirAccess.get_files_at(Globals.playlist_directory)
	
	# Populate the playlists
	for playlist_file in files:
		if playlist_file.ends_with(".m3u"):
			playlists.append(playlist_file)

# ------------- Refresh UI -------------
func update_playlist_browser() -> void:
	# Clear old elements
	for child in playlist_list.get_children():
		playlist_list.remove_child(child)
		child.queue_free()
	
	# Populate fresh elements
	for playlist_filename in playlists:
		var playlist_list_item: PlaylistListItem = LIST_ITEM_SCENE.instantiate()
		playlist_list_item.filename = playlist_filename
		playlist_list.add_child(playlist_list_item)
	
