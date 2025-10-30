# Adjust the viewport size of the object outline display
# To prevent the outline from deviating from the object
extends Control

@onready var sub_viewport = $OutlineContainer/SubViewport
@onready var sub_viewport_container = $OutlineContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent_viewport_size = get_viewport().size
	sub_viewport_container.size = parent_viewport_size
	sub_viewport.size = parent_viewport_size
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
