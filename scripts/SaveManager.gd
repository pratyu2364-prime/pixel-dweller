class_name SaveManager
extends RefCounted


static func save(data: Dictionary, path: String = "user://save.json") -> void:
	data["last_saved_at"] = Time.get_unix_time_from_system()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))


static func load(path: String = "user://save.json") -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	if text.is_empty():
		return {}
	var result: Variant = JSON.parse_string(text)
	if typeof(result) != TYPE_DICTIONARY:
		return {}
	return result


static func save_dweller(dweller: Dweller, path: String = "user://save.json") -> void:
	var data := {
		"hunger": dweller.hunger,
		"energy": dweller.energy,
		"mood": dweller.mood,
		"stage": dweller.stage,
	}
	save(data, path)


static func load_into_dweller(dweller: Dweller, path: String = "user://save.json") -> float:
	var data := SaveManager.load(path)
	if data.is_empty():
		return 0.0
	if data.has("hunger"):
		dweller.hunger = data["hunger"]
	if data.has("energy"):
		dweller.energy = data["energy"]
	if data.has("mood"):
		dweller.mood = data["mood"]
	if data.has("stage"):
		dweller.stage = data["stage"]
	if data.has("last_saved_at"):
		return data["last_saved_at"]
	return 0.0
