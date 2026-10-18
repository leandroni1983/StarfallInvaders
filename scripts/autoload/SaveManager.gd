extends Node

const SAVE_PATH := "user://save.dat"
const SAVE_JSON := "user://save.json"
const SAVE_VERSION := 1

var _cache: Dictionary = {
	"version": SAVE_VERSION,
	"high_score": 0,
	"best_cycle": 0,
}

func _ready() -> void:
	load_data()

func load_data() -> Dictionary:
	if FileAccess.file_exists(SAVE_JSON):
		var fj: FileAccess = FileAccess.open(SAVE_JSON, FileAccess.READ)
		if fj != null:
			var p: Variant = JSON.parse_string(fj.get_as_text())
			fj.close()
			if p is Dictionary:
				var d: Dictionary = p
				_cache = {
					"version": SAVE_VERSION,
					"high_score": maxi(int(d.get("high_score", 0)), 0),
					"best_cycle": maxi(int(d.get("best_cycle", 0)), 0),
				}
				return _cache.duplicate()

	if FileAccess.file_exists(SAVE_PATH):
		var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f != null:
			var v: int = f.get_32()
			f.close()
			if v >= 0:
				_cache["high_score"] = v
				_cache["best_cycle"] = 0
				return _cache.duplicate()

	return _cache.duplicate()

func save_high_score(score: int) -> void:
	var s: int = maxi(score, 0)
	if s >= _cache.get("high_score", 0):
		_cache["high_score"] = s

	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_32(_cache["high_score"])
		f.close()

	var dj: Dictionary = {
		"version": SAVE_VERSION,
		"high_score": _cache["high_score"],
		"best_cycle": _cache["best_cycle"],
	}
	var fj: FileAccess = FileAccess.open(SAVE_JSON, FileAccess.WRITE)
	if fj != null:
		fj.store_string(JSON.stringify(dj))
		fj.close()

func get_high_score() -> int:
	return _cache.get("high_score", 0)

func get_best_cycle() -> int:
	return _cache.get("best_cycle", 0)

func set_best_cycle(c: int) -> void:
	var nc: int = maxi(c, 0)
	if nc > _cache.get("best_cycle", 0):
		_cache["best_cycle"] = nc
		save_high_score(_cache.get("high_score", 0))
