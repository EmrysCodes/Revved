extends Node
## Short original tones follow the same master volume as the rest of the game.
var focus_player:AudioStreamPlayer
var confirm_player:AudioStreamPlayer
var last_focus_msec:=-1000
func _ready() -> void:
	focus_player=AudioStreamPlayer.new();add_child(focus_player);focus_player.stream=load("res://assets/audio/interface/focus.wav");focus_player.volume_db=-22
	confirm_player=AudioStreamPlayer.new();add_child(confirm_player);confirm_player.stream=load("res://assets/audio/interface/confirm.wav");confirm_player.volume_db=-18
	get_tree().node_added.connect(watch)
	for node in get_parent().find_children("*","BaseButton",true,false):watch(node)
func watch(node:Node) -> void:
	if not node is BaseButton or not get_parent().is_ancestor_of(node) or node.has_meta("menu_tones"):return
	node.set_meta("menu_tones",true)
	node.mouse_entered.connect(focus.bind(node));node.focus_entered.connect(focus.bind(node))
	node.pressed.connect(func():if is_instance_valid(confirm_player):confirm_player.play())
func focus(button:BaseButton) -> void:
	if button.disabled or not button.is_visible_in_tree() or Time.get_ticks_msec()-last_focus_msec<60:return
	last_focus_msec=Time.get_ticks_msec();focus_player.play()
