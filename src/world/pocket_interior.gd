class_name PocketInterior
extends Node3D
## Builds the geometry of a pocket space from its PocketSpaceInfo (interior coordinates:
## origin at the floor centre). Everything is drawn on the pocket visual layer.

const _PALETTES := {
	PocketSpaceInfo.Kind.HALL: [Color(0.16, 0.15, 0.19), Color(1.0, 0.75, 0.35), Color(0.75, 0.72, 0.7)],
	PocketSpaceInfo.Kind.GARDEN: [Color(0.07, 0.13, 0.09), Color(0.45, 1.0, 0.6), Color(0.4, 0.38, 0.32)],
	PocketSpaceInfo.Kind.BAZAAR: [Color(0.2, 0.11, 0.07), Color(1.0, 0.6, 0.2), Color(0.55, 0.35, 0.25)],
	PocketSpaceInfo.Kind.CONCOURSE: [Color(0.07, 0.09, 0.15), Color(0.3, 0.85, 1.0), Color(0.6, 0.66, 0.75)],
}

var info: PocketSpaceInfo
var inner_door_local: Transform3D
## The inside of the doorway, on the entrance wall.
var door_view: DoorwayView


func build(pocket: PocketSpaceInfo, doorway: DoorwayInfo) -> void:
	info = pocket
	inner_door_local = pocket.inner_door
	name = "Pocket_%d_%d_%d" % [pocket.cell.x, pocket.cell.y, pocket.cell.z]
	var palette: Array = _PALETTES[pocket.kind]
	var contents := pocket.contents()

	var room_material := ShaderMaterial.new()
	room_material.shader = load("res://src/world/shaders/pocket_surface.gdshader")
	room_material.set_shader_parameter("base_color", palette[0])
	room_material.set_shader_parameter("line_color", palette[1])
	var room_mesh := BoxMesh.new()
	room_mesh.size = pocket.size
	room_mesh.flip_faces = true
	var room := MeshInstance3D.new()
	room.name = "Room"
	room.mesh = room_mesh
	room.position = Vector3(0, pocket.size.y * 0.5, 0)
	room.material_override = room_material
	add_child(room)

	var pillar_material := StandardMaterial3D.new()
	pillar_material.albedo_color = palette[2]
	pillar_material.metallic = 0.4
	pillar_material.roughness = 0.35
	_add_boxes("Pillars", contents.pillars, PackedColorArray(), pillar_material)

	var light_material := StandardMaterial3D.new()
	light_material.albedo_color = Color.WHITE
	light_material.emission_enabled = true
	light_material.emission = Color(1.0, 0.93, 0.8)
	light_material.emission_energy_multiplier = 4.0
	_add_boxes("Lights", contents.lights, PackedColorArray(), light_material)

	var prop_material := StandardMaterial3D.new()
	prop_material.vertex_color_use_as_albedo = true
	prop_material.roughness = 0.6
	if pocket.kind == PocketSpaceInfo.Kind.CONCOURSE:
		prop_material.emission_enabled = true
		prop_material.emission = Color(0.2, 0.6, 0.8)
	_add_boxes("Props", contents.props, contents.prop_colors, prop_material)

	var crystal_material := StandardMaterial3D.new()
	crystal_material.albedo_color = Color(0.3, 0.2, 0.5)
	crystal_material.emission_enabled = true
	crystal_material.emission = palette[1]
	crystal_material.emission_energy_multiplier = 3.0
	var crystal_mesh := PrismMesh.new()
	crystal_mesh.size = contents.monument.size
	var crystal := MeshInstance3D.new()
	crystal.name = "Monument"
	crystal.mesh = crystal_mesh
	crystal.position = contents.monument.get_center()
	crystal.material_override = crystal_material
	add_child(crystal)

	for z: float in [-pocket.size.z * 0.25, pocket.size.z * 0.25]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, pocket.size.y * 0.7, z)
		lamp.omni_range = maxf(pocket.size.x, pocket.size.z) * 0.6
		lamp.light_energy = 2.0
		lamp.light_color = palette[1].lerp(Color.WHITE, 0.6)
		lamp.light_cull_mask = PocketManager.POCKET_LAYERS
		add_child(lamp)

	door_view = DoorwayView.new()
	add_child(door_view)
	door_view.build(doorway)
	door_view.name = "InnerDoor"
	door_view.transform = inner_door_local

	for node in find_children("*", "VisualInstance3D", true, false):
		(node as VisualInstance3D).layers = PocketManager.POCKET_LAYERS


## World transform of the inner door.
func inner_door_global() -> Transform3D:
	return global_transform * inner_door_local


func _add_boxes(node_name: String, boxes: Array[AABB], colors: PackedColorArray, material: Material) -> void:
	if boxes.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = not colors.is_empty()
	multimesh.mesh = ChunkView.box_mesh()
	multimesh.instance_count = boxes.size()
	for i in boxes.size():
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(boxes[i].size), boxes[i].get_center()))
		if multimesh.use_colors:
			multimesh.set_instance_color(i, colors[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
