class_name PersonAgent
extends Node3D
## A person near the player (specs people-in-the-city, realistic-people): a jointed body sized and
## dressed by the person's look — hips, torso, neck, head with hair, arms with elbows and hands,
## legs with knees and feet — that walks with swinging arms and bending knees at the pace it moves,
## and stands breathing when still. The node origin is at the soles; the figure faces −z.

const DETAIL_RANGE := 30.0
const ARM_SWING := 0.7
const KNEE_BEND := 0.75
const TURN_RATE := 8.0

static var _capsule: CapsuleMesh
static var _sphere: SphereMesh
static var _box: BoxMesh
static var _cone: CylinderMesh
static var _materials: Dictionary = {}

var person_key: String = ""
var label: String = ""
var activity: String = ""
var look: FigureLook
## Walking phase in radians (tests read it).
var walk_phase: float:
	get:
		return _phase

var _body: Node3D          # everything above the soles, bobs while walking
var _torso: Node3D
var _head: Node3D
var _hips: Array[Node3D] = []
var _knees: Array[Node3D] = []
var _shoulders: Array[Node3D] = []
var _elbows: Array[Node3D] = []
var _top_parts: Array[MeshInstance3D] = []
var _phase: float = 0.0
var _breath: float = 0.0
var _last_position := Vector3.INF


func _init(p_look: FigureLook = null) -> void:
	if _capsule == null:
		_capsule = CapsuleMesh.new()
		_capsule.radius = 0.5
		_capsule.height = 2.0
		_capsule.radial_segments = 10
		_capsule.rings = 4
		_sphere = SphereMesh.new()
		_sphere.radius = 0.5
		_sphere.height = 1.0
		_sphere.radial_segments = 12
		_sphere.rings = 6
		_box = BoxMesh.new()
		_cone = CylinderMesh.new()
		_cone.top_radius = 0.3
		_cone.bottom_radius = 0.5
		_cone.height = 1.0
		_cone.radial_segments = 12
		_cone.rings = 1
	configure(p_look if p_look != null else FigureLook.generic(str(get_instance_id())))


## Builds the body for a look (replacing any earlier one).
func configure(p_look: FigureLook) -> void:
	look = p_look
	if _body != null:
		remove_child(_body)
		_body.queue_free()
	_hips.clear()
	_knees.clear()
	_shoulders.clear()
	_elbows.clear()
	_top_parts.clear()
	var h := look.height
	var g := look.girth
	_body = Node3D.new()
	add_child(_body)
	var hip_y := 0.53 * h
	var thigh := 0.245 * h
	var shin := 0.245 * h
	var l := look.limbs
	var dress := look.garment == FigureLook.Garment.DRESS
	var skirted := look.garment != FigureLook.Garment.TROUSERS
	var shin_color := look.legwear if skirted else look.bottom
	# Pelvis and legs; a skirt or dress hangs from the waist and does not swing with the legs.
	var pelvis := _part(_body, _sphere, Vector3(0, hip_y + 0.02 * h, 0), Vector3(0.2 * h * look.hips * g, 0.11 * h, 0.13 * h * g), look.top if dress else look.bottom)
	if dress:
		_top_parts.append(pelvis)
	if skirted:
		var hem := 0.25 * h if dress else 0.31 * h
		var top_y := hip_y + 0.06 * h
		var skirt := _part(_body, _cone, Vector3(0, (top_y + hem) * 0.5, 0), Vector3(0.34 * h * look.hips * g, top_y - hem, 0.28 * h * look.hips * g), look.top if dress else look.bottom)
		if dress:
			_top_parts.append(skirt)
	for side: float in [-1.0, 1.0]:
		var hip := _joint(_body, Vector3(side * 0.055 * h * look.hips, hip_y, 0))
		_part(hip, _capsule, Vector3(0, -thigh * 0.5, 0), Vector3(0.085 * h * g * l, thigh * 0.58, 0.09 * h * g * l), shin_color if skirted else look.bottom)
		var knee := _joint(hip, Vector3(0, -thigh, 0))
		_part(knee, _capsule, Vector3(0, -shin * 0.48, 0), Vector3(0.066 * h * l, shin * 0.56, 0.072 * h * l), shin_color)
		var foot := _part(knee, _box, Vector3(0, -shin - 0.012 * h, -0.03 * h), Vector3(0.055 * h, 0.04 * h, 0.14 * h), look.shoes)
		foot.visibility_range_end = DETAIL_RANGE
		_hips.append(hip)
		_knees.append(knee)
	# Torso, leaning forward with age.
	_torso = _joint(_body, Vector3(0, hip_y + 0.05 * h, 0))
	_torso.rotation.x = -look.stoop
	# Abdomen from the belt up, then a chest that is broadest at the shoulders.
	_top_parts.append(_part(_torso, _capsule, Vector3(0, 0.07 * h, 0), Vector3(0.19 * h * look.waist * g, 0.09 * h, 0.12 * h * g), look.top))
	_top_parts.append(_part(_torso, _capsule, Vector3(0, 0.19 * h, 0), Vector3(0.22 * h * look.shoulders * g, 0.1 * h, 0.125 * h * g), look.top))
	_top_parts.append(_part(_torso, _capsule, Vector3(0, 0.255 * h, 0), Vector3(0.27 * h * look.shoulders * sqrt(g), 0.04 * h, 0.1 * h), look.top))
	# A belly and a bust are soft volumes blended into the torso, wide and shallow.
	if look.belly > 0.05:
		_top_parts.append(_part(_torso, _sphere, Vector3(0, 0.09 * h, -0.018 * h * g), Vector3(0.2 * h * look.waist * g, 0.15 * h, 0.13 * h * g * (0.8 + 0.3 * look.belly)), look.top))
	if look.bust > 0.05:
		var depth := 0.05 * h * (0.7 + 0.3 * look.bust) * sqrt(g)
		for side: float in [-1.0, 1.0]:
			_top_parts.append(_part(_torso, _sphere, Vector3(side * 0.03 * h * look.shoulders, 0.19 * h, -0.04 * h * g), Vector3(0.1 * h * look.shoulders * sqrt(g), 0.075 * h * (0.85 + 0.15 * look.bust), depth * 2.0), look.top))
	for side: float in [-1.0, 1.0]:
		var shoulder := _joint(_torso, Vector3(side * 0.135 * h * look.shoulders * sqrt(g), 0.265 * h, 0))
		_top_parts.append(_part(shoulder, _capsule, Vector3(0, -0.078 * h, 0), Vector3(0.068 * h * l, 0.092 * h, 0.068 * h * l), look.top))
		var elbow := _joint(shoulder, Vector3(0, -0.155 * h, 0))
		_top_parts.append(_part(elbow, _capsule, Vector3(0, -0.07 * h, 0), Vector3(0.056 * h * l, 0.084 * h, 0.056 * h * l), look.top))
		var hand := _part(elbow, _sphere, Vector3(0, -0.15 * h, 0), Vector3(0.05 * h, 0.06 * h, 0.035 * h), look.skin)
		hand.visibility_range_end = DETAIL_RANGE
		_shoulders.append(shoulder)
		_elbows.append(elbow)
	# Neck and head; the head counters part of the stoop to look ahead.
	_part(_torso, _capsule, Vector3(0, 0.305 * h, 0), Vector3(0.05 * h, 0.03 * h, 0.05 * h), look.skin)
	_head = _joint(_torso, Vector3(0, 0.325 * h, 0))
	_head.rotation.x = look.stoop * 0.7
	_part(_head, _sphere, Vector3(0, 0.062 * h, 0), Vector3(0.105 * h, 0.13 * h, 0.12 * h), look.skin)
	var nose := _part(_head, _sphere, Vector3(0, 0.045 * h, -0.06 * h), Vector3(0.022 * h, 0.03 * h, 0.03 * h), look.skin.darkened(0.08))
	nose.visibility_range_end = DETAIL_RANGE
	var brows := _part(_head, _box, Vector3(0, 0.07 * h, -0.056 * h), Vector3(0.07 * h, 0.006 * h, 0.012 * h), look.hair.darkened(0.2))
	brows.visibility_range_end = DETAIL_RANGE
	_hair(h)
	set_activity(activity if not activity.is_empty() else "at home")


func _hair(h: float) -> void:
	if look.hair_style == FigureLook.Hair.BALD:
		return
	_part(_head, _sphere, Vector3(0, 0.08 * h, 0.01 * h), Vector3(0.113 * h, 0.105 * h, 0.128 * h), look.hair)
	match look.hair_style:
		FigureLook.Hair.LONG:
			var long := _part(_head, _capsule, Vector3(0, 0.02 * h, 0.055 * h), Vector3(0.1 * h, 0.075 * h, 0.04 * h), look.hair)
			long.visibility_range_end = DETAIL_RANGE
		FigureLook.Hair.BUN:
			var bun := _part(_head, _sphere, Vector3(0, 0.1 * h, 0.07 * h), Vector3(0.05 * h, 0.05 * h, 0.05 * h), look.hair)
			bun.visibility_range_end = DETAIL_RANGE


func _joint(parent: Node3D, at: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.position = at
	parent.add_child(joint)
	return joint


func _part(parent: Node3D, mesh: Mesh, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.scale = size
	part.material_override = _material(color)
	parent.add_child(part)
	return part


## Height of the top of the head above the soles.
func top_height() -> float:
	return look.height


## Dresses the figure for what they are doing: work clothes at work, a gang's dark red jacket,
## a warden's slate uniform, everyday clothes otherwise.
func set_activity(kind: String) -> void:
	activity = kind
	var color := look.top
	match kind:
		"working":
			color = look.work_top
		"gang":
			color = ArtStyle.mute(Color(0.62, 0.1, 0.12), 0.7)
		"warden":
			color = ArtStyle.mute(Color(0.22, 0.3, 0.45), 0.8)
	var material := _material(color)
	for part in _top_parts:
		part.material_override = material


## Turns smoothly to face a direction on the ground plane.
func face(direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	var target := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target, minf(1.0, delta * TURN_RATE))


## Walks at the speed the figure moved since the last frame, or stands and breathes.
func animate(delta: float) -> void:
	var speed := 0.0
	if _last_position != Vector3.INF and delta > 0.0:
		var step := global_position - _last_position
		step.y = 0.0
		speed = step.length() / delta
	_last_position = global_position
	var h := look.height
	var stride := 0.38 * h * (0.75 + 0.25 * look.pace)
	if speed > 0.2:
		# Two steps per cycle: the phase advances by π per stride length walked.
		_phase += minf(speed, 9.0) * delta / stride * PI
	else:
		_phase = lerpf(_phase, roundf(_phase / PI) * PI, minf(1.0, delta * 6.0))
	_breath += delta * 1.6
	var amount := clampf(speed / 1.4, 0.0, 1.0) if speed > 0.2 else 0.0
	var swing := 0.42 * (0.7 + 0.3 * look.pace)
	for i in 2:
		var leg_phase := _phase + PI * i
		var thigh := sin(leg_phase) * swing
		_hips[i].rotation.x = thigh
		_knees[i].rotation.x = -KNEE_BEND * maxf(0.0, cos(leg_phase)) * swing * 1.6
		var arm := -thigh * ARM_SWING
		_shoulders[i].rotation.x = arm
		_elbows[i].rotation.x = 0.18 + 0.25 * maxf(0.0, arm)
	if amount == 0.0:
		for i in 2:
			_hips[i].rotation.x *= 0.0
			_knees[i].rotation.x = 0.0
			_shoulders[i].rotation.x = sin(_breath * 0.5 + i) * 0.03
			_elbows[i].rotation.x = 0.12
	_body.position.y = (cos(_phase * 2.0) * 0.012 * h) * amount
	_torso.scale = Vector3(1.0, 1.0 + sin(_breath) * 0.008, 1.0)


static func _material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.85
		_materials[key] = m
	return _materials[key]
