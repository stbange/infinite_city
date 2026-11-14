class_name MessageQueue
extends RefCounted
## Short messages from many systems in one place (spec hud-panels / Messages): each source's new
## message shows for DURATION seconds, newest last, at most MAX_LINES at a time.

const DURATION := 6.0
const MAX_LINES := 4

var _last: Dictionary = {}       # source -> last text seen
var _items: Array[Array] = []    # [time, text]


## Records a source's current message; only a changed, non-empty text counts as new.
func push(source: String, text: String, now: float) -> void:
	if text == str(_last.get(source, "")):
		return
	_last[source] = text
	if not text.is_empty():
		_items.append([now, text])


func lines(now: float) -> PackedStringArray:
	var result := PackedStringArray()
	var kept: Array[Array] = []
	for item in _items:
		if now - float(item[0]) < DURATION:
			kept.append(item)
	_items = kept
	for i in range(maxi(0, kept.size() - MAX_LINES), kept.size()):
		result.append(str(kept[i][1]))
	return result
