# Handles parameter input for the shader
class_name OptionToggler
extends Node

# Each string in this array corresponds to a boolean in the shader and an input 
# action to reduce code repetition for simple toggles
const settings = ["ambient_occlusion", "glow", "mirror"]

onready var material: ShaderMaterial = get_parent().material

func _input(event: InputEvent) -> void:
	for toggle in settings:
		if Input.is_action_just_pressed(toggle):
			material.set_shader_param(toggle, not material.get_shader_param(toggle))
	for i in range(9):
		if Input.is_key_pressed(KEY_0 + i):
			material.set_shader_param("palette", i)
	if event.is_action_pressed("mouse_lock", false):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("randomize", false):
		material.set_shader_param("scale_range", rand_range(0.5, 1.5))
		material.set_shader_param("scale_center", rand_range(1.75, 5.0))
