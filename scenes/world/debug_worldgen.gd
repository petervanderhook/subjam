@tool
extends TileMapLayer


@export var rebuild_in_editor := false:
	set(value):
		if not Engine.is_editor_hint():
			print("Returning")
			return
		if not value:
			print("Returning")
			return
		
		rebuild_in_editor = false
		
		var level = get_parent()
		if level == null:
			push_warning("No parent level node found")
			return
			
		level.load_map()
		
