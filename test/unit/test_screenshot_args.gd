extends GutTest
## Command-line parsing of the screenshot tool.


func test_parses_key_value_pairs() -> void:
	var args := ScreenshotCapture.parse_args(PackedStringArray(["--screenshot=out.png", "--pos=1.5,-640,3", "--yaw=45"]))
	assert_eq(args["screenshot"], "out.png")
	assert_eq(args["pos"], "1.5,-640,3")
	assert_eq(args["yaw"], "45")


func test_ignores_other_arguments() -> void:
	var args := ScreenshotCapture.parse_args(PackedStringArray(["plain", "-x", "--flag"]))
	assert_eq(args.size(), 1)
	assert_true(args.has("flag"))


func test_parses_vectors() -> void:
	var v := ScreenshotCapture.parse_vector("1.5,-640,3")
	assert_eq(v, PackedFloat64Array([1.5, -640.0, 3.0]))
