extends GutTest
## Spec release-candidate: Builds, Accessibility, Sound, Save slots (rules).

const TEST_SETTINGS := "user://test_rc_settings.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(TEST_SETTINGS)
	FactionPalette.colorblind = false
	GameSettings.reduced_motion = false


func test_three_export_presets() -> void:
	var file := ConfigFile.new()
	assert_eq(file.load("res://export_presets.cfg"), OK)
	var platforms := {}
	for section in file.get_sections():
		if section.ends_with(".options"):
			continue
		platforms[str(file.get_value(section, "platform"))] = true
		assert_string_contains(str(file.get_value(section, "include_filter")), "data/*.json", "the data tables ship with the game")
		assert_string_contains(str(file.get_value(section, "exclude_filter")), "test/*", "tests stay out")
		assert_string_starts_with(str(file.get_value(section, "export_path")), "build/")
	assert_eq(platforms.keys().size(), 3)
	for platform: String in ["Linux", "Windows Desktop", "macOS"]:
		assert_true(platforms.has(platform), platform)


func test_colour_blind_palette() -> void:
	var red := Color(0.95, 0.1, 0.15)
	assert_eq(FactionPalette.display(red), red)
	FactionPalette.colorblind = true
	assert_has(FactionPalette.SAFE, FactionPalette.display(red))
	assert_has(FactionPalette.SAFE, FactionPalette.display(Color(0.2, 0.9, 0.3)))


func test_settings_kept_and_applied() -> void:
	var settings := GameSettings.new()
	settings.text_scale = 1.4
	settings.colorblind = true
	settings.reduced = true
	assert_true(settings.rebind("interact", KEY_T))
	assert_false(settings.rebind("not_an_action", KEY_T))
	settings.save(TEST_SETTINGS)
	var loaded := GameSettings.new()
	loaded.load_from(TEST_SETTINGS)
	assert_almost_eq(loaded.text_scale, 1.4, 0.001)
	assert_true(loaded.colorblind)
	assert_true(loaded.reduced)
	assert_eq(int(loaded.bindings["interact"]), KEY_T)
	loaded.apply(null, null)
	assert_true(FactionPalette.colorblind)
	assert_true(GameSettings.reduced_motion)
	var keys := []
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
	assert_eq(keys, [KEY_T])
	GameSettings.apply_binding("interact", KEY_E)
	assert_almost_eq(get_tree().root.content_scale_factor, 1.4, 0.001)
	get_tree().root.content_scale_factor = 1.0


func test_music_follows_the_moment() -> void:
	assert_eq(Ambience.music_for(false, false), Vector2.ZERO)
	assert_gt(Ambience.music_for(true, false).x, 0.0, "a pulse in a chase")
	assert_gt(Ambience.music_for(false, true).y, 0.0, "a drone under a scene")
	assert_eq(Ambience.music_for(true, true).y, 0.0, "the chase wins")
