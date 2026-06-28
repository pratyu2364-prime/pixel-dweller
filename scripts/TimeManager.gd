class_name TimeManager
extends RefCounted


static func elapsed_since(last_saved_at: float) -> float:
	var now := Time.get_unix_time_from_system()
	return max(0.0, now - last_saved_at)
