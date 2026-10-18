extends SceneTree
## Loads every script once so parse and compile errors show up in one headless run.


func _initialize() -> void:
	var failed := 0
	for path in _scripts("res://"):
		var s: Script = load(path)
		if s == null or not s.can_instantiate() and not path.ends_with("check_scripts.gd"):
			if not (s is GDScript and (s as GDScript).is_abstract()):
				printerr("FAILED: ", path)
				failed += 1
	print("checked %d scripts, %d failed" % [_scripts("res://").size(), failed])
	quit(1 if failed > 0 else 0)


func _scripts(dir: String) -> Array:
	var out: Array = []
	for d in DirAccess.get_directories_at(dir):
		if d.begins_with(".") or d in ["docs", "tools", "art"]:
			continue
		out.append_array(_scripts(dir.path_join(d)))
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	return out
