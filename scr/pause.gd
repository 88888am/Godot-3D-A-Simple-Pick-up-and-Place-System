extends Control

@onready var sub_viewport = $PauseUI/PauseUI
@onready var sub_viewport_container = $PauseUI

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	var parent_viewport_size = get_viewport().size
	sub_viewport.size = parent_viewport_size
	sub_viewport_container.size = parent_viewport_size
	self.visible = get_tree().paused
	self.process_mode = Node.PROCESS_MODE_ALWAYS


func game_pause() -> void:
	get_tree().paused = true
	self.visible = true
	$"../AimPoint".visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func game_continue() -> void:
	get_tree().paused = false
	self.visible = false
	$"../AimPoint".visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Called every time an input event is received
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused:
			game_continue()
		else:
			game_pause()


func _on_resume_pressed() -> void:
	if get_tree().paused:
		game_continue()
	else:
		game_pause()


func _on_quit_pressed() -> void:
	get_tree().quit()
