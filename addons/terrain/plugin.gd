@tool
extends EditorPlugin

const Toolbar = preload("./ui/toolbar.tscn")

func _enter_tree() -> void:
	# Initialization of the plugin goes here.

	var toolbar = Toolbar.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, toolbar)

	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
