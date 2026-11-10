class_name BackgroundJobs
extends Node
## Results computed on worker threads and cached by key (spec content-data / Background jobs).
## Jobs must be pure (generators are), so running them off the main thread is safe.

var _mutex := Mutex.new()
var _results: Dictionary = {}
var _pending: Dictionary = {}   # key -> task id
var _finished: Dictionary = {}  # key -> result, filled by workers


func _process(_delta: float) -> void:
	poll()


## Starts `job` (a Callable returning the result) unless `key` is known already.
func submit(key: Variant, job: Callable) -> void:
	if _results.has(key) or _pending.has(key):
		return
	_pending[key] = WorkerThreadPool.add_task(_run.bind(key, job))


func _run(key: Variant, job: Callable) -> void:
	var value: Variant = job.call()
	_mutex.lock()
	_finished[key] = value
	_mutex.unlock()


## Moves finished results into the cache (main thread).
func poll() -> void:
	_mutex.lock()
	var done := _finished.duplicate()
	_finished.clear()
	_mutex.unlock()
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
