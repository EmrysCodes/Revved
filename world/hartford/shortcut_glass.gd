extends Area3D
## Arcade shortcut glass: visual pane and trigger; structural columns stay solid.
var broken := false
func _ready() -> void:
	body_entered.connect(_entered)
func _entered(body: Node3D) -> void:
	if broken or not body is CharacterBody3D:
		return
	broken = true
	$Pane.hide()
	$Shards.restart()
	$Shards.emitting = true
func restore() -> void:
	broken = false
	$Pane.show()
	$Shards.emitting = false
