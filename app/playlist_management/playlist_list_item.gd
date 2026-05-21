class_name PlaylistListItem
extends Control

# -----------------------------------------------------------------
# Setup
# -----------------------------------------------------------------
# Provided parameter
@export var filename: String = 'playlist.m3u'

# Display element
@onready var playlist_name_label: Label = $Panel/OuterMargins/PanelLayoutBox/PlaylistNameLabel

# Setup on instantiation
func _ready() -> void:
	# Set the label text
	var title = filename.get_file().rsplit(".", false, 1)[0]
	playlist_name_label.text = title
	
# -----------------------------------------------------------------
# Interactivity
# -----------------------------------------------------------------

# ------------- Open playlist details -------------
func _on_open_detail_button_pressed() -> void:
	# Announce to ancestors that the details should open
	SignalBus.open_playlist_detail.emit(filename)
