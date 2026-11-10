class_name BackgroundJobs
extends Node
## Results computed on worker threads and cached by key (spec content-data / Background jobs).
## Jobs must be pure (generators are), so running them off the main thread is safe.

## State shared with worker threads; tasks keep it alive even if this node is freed first.
class Shared:
	extends RefCounted
	var mutex := Mutex.new()
	var finished: Dictionary = {}   # key -> result, filled by workers


var _shared := Shared.new()
var _results: Dictionary = {}
var _pending: Dictionary = {}   # key -> task id


func _process(_delta: float) -> void:
	poll()


## Starts `job` (a Callable returning the result) unless `key` is known already.
func submit(key: Variant, job: Callable) -> void:
	if _results.has(key) or _pending.has(key):
		return
	_pending[key] = WorkerThreadPool.add_task(BackgroundJobs._run.bind(_shared, key, job))


static func _run(shared: Shared, key: Variant, job: Callable) -> void:
	var value: Variant = job.call()
	shared.mutex.lock()
	shared.finished[key] = value
	shared.mutex.unlock()


## Moves finished results into the cache (main thread).
func poll() -> void:
	_shared.mutex.lock()
	var done := _shared.finished.duplicate()
	_shared.finished.clear()
	_shared.mutex.unlock()
	for key: Variant in done:
		WorkerThreadPool.wait_for_task_completion(_pending[key])
		_pending.erase(key)
		_results[key] = done[key]


func is_ready(key: Variant) -> bool:
	return _results.has(key)


func result(key: Variant) -> Variant:
	return _results.get(key)


## Computes `job` now on this thread if it is not cached yet, and returns the result.
func get_now(key: Variant, job: Callable) -> Variant:
	if _pending.has(key):
		WorkerThreadPool.wait_for_task_completion(_pending[key])
		poll()
	if not _results.has(key):
		_results[key] = job.call()
	return _results[key]
