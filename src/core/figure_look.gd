class_name FigureLook
extends RefCounted
## How a person looks as a figure (spec realistic-people / Looks): height and build from age and
## pronoun, skin, hair that greys and thins with age, everyday and work clothes in muted tones,
## an older person's stoop and slower pace. A pure function of the person and the seed.

const SALT_LOOK := 220

## Realistic skin tones, light to dark.
const SKIN: Array[Color] = [
	Color(0.95, 0.8, 0.69), Color(0.9, 0.73, 0.6), Color(0.82, 0.63, 0.48), Color(0.7, 0.5, 0.36),
	Color(0.56, 0.38, 0.26), Color(0.43, 0.28, 0.19), Color(0.31, 0.2, 0.14),
]
const HAIR: Array[Color] = [
	Color(0.06, 0.05, 0.045), Color(0.16, 0.11, 0.07), Color(0.3, 0.2, 0.12), Color(0.4, 0.2, 0.11),
	Color(0.66, 0.54, 0.35),
]
const GREY_HAIR := Color(0.56, 0.56, 0.55)
const WHITE_HAIR := Color(0.84, 0.84, 0.82)
## Everyday tops and trousers: charcoal, slate, olive, rust, navy, oatmeal, wine, grey-teal.
const CASUAL_TOPS: Array[Color] = [
	Color(0.2, 0.2, 0.22), Color(0.36, 0.4, 0.45), Color(0.34, 0.36, 0.24), Color(0.5, 0.3, 0.2),
	Color(0.16, 0.2, 0.32), Color(0.7, 0.66, 0.58), Color(0.38, 0.17, 0.2), Color(0.3, 0.4, 0.4),
]
const BOTTOMS: Array[Color] = [
	Color(0.2, 0.25, 0.36), Color(0.15, 0.15, 0.16), Color(0.46, 0.42, 0.33), Color(0.08, 0.08, 0.09),
	Color(0.3, 0.29, 0.28),
]
## Work clothes by skill: hands ochre overalls, numbers dark suit, care pale scrubs, words white
## shirt, tech dark grey.
const WORK_TOPS := {
	"hands": Color(0.55, 0.42, 0.2), "numbers": Color(0.14, 0.15, 0.18), "care": Color(0.62, 0.72, 0.76),
	"words": Color(0.82, 0.82, 0.8), "tech": Color(0.24, 0.25, 0.27),
}
const SHOES := Color(0.07, 0.065, 0.06)

enum Hair { BALD, SHORT, LONG, BUN }
enum Build { SLIM, AVERAGE, ATHLETIC, STOCKY, HEAVY }
enum Garment { TROUSERS, SKIRT, DRESS }
## Tights for skirts and dresses (or bare legs in skin tone).
const TIGHTS: Array[Color] = [Color(0.06, 0.06, 0.065), Color(0.18, 0.17, 0.17)]

var age: int = 35
## Metres from the soles to the top of the head.
var height: float = 1.72
## Shoulder width and hip width relative to an average build (1.0).
var shoulders: float = 1.0
var hips: float = 1.0
## Body fullness (1.0 average).
var girth: float = 1.0
## Forward lean of the upper body in radians (older people stoop).
var stoop: float = 0.0
var build: int = Build.AVERAGE
## Waist width relative to an average build; bust 0 (none) to about 1.3; belly 0 (flat) to 1;
## limbs: thickness of arms and legs.
var waist: float = 1.0
var bust: float = 0.0
var belly: float = 0.0
var limbs: float = 1.0
var garment: int = Garment.TROUSERS
var legwear := TIGHTS[0]
## Walking cadence relative to an adult (older people walk slower, children quicker).
var pace: float = 1.0
var skin := SKIN[2]
var hair := HAIR[1]
var hair_style: int = Hair.SHORT
var top := CASUAL_TOPS[0]
var work_top := CASUAL_TOPS[1]
var bottom := BOTTOMS[0]
var shoes := SHOES


## The look of a resident.
static func of(person: PersonInfo, seed_value: int) -> FigureLook:
	var look := FigureLook.new()
	var rng := CellRandom.new(DetHash.hash3(seed_value, SALT_LOOK, person.id.district.x * 4096 + person.id.district.z,
			person.id.district.y, person.id.local))
	look.age = person.age
	var base := 1.64 if person.pronoun == "she" else (1.77 if person.pronoun == "he" else 1.7)
	# Sum of three uniforms: close to a bell curve around the base, about ±7 cm.
	var spread := (rng.next_float() + rng.next_float() + rng.next_float() - 1.5) * 0.1
	var adult := base + spread
	if person.age < 18:
		look.height = lerpf(0.8, adult, clampf((person.age - 2) / 16.0, 0.0, 1.0))
	else:
		look.height = adult * (1.0 - 0.04 * smoothstep(60.0, 90.0, person.age))
	look.shoulders = (1.08 if person.pronoun == "he" else (0.94 if person.pronoun == "she" else 1.0)) * rng.range_float(0.94, 1.06)
	look.hips = (1.06 if person.pronoun == "she" else (0.96 if person.pronoun == "he" else 1.0)) * rng.range_float(0.95, 1.05)
	look.girth = rng.range_float(0.88, 1.22) + 0.1 * smoothstep(30.0, 60.0, person.age)
	if person.age < 14:
		look.girth *= 0.9
	look.stoop = rng.range_float(0.1, 0.24) * smoothstep(62.0, 85.0, person.age)
	look.pace = 1.12 if person.age < 14 else (1.0 - 0.3 * smoothstep(60.0, 88.0, person.age))
	look.skin = SKIN[rng.next_int(SKIN.size())]
	var greying := smoothstep(42.0, 78.0, person.age)
	var roll := rng.next_float()
	look.hair = HAIR[rng.next_int(HAIR.size())]
	if roll < greying * 0.5:
		look.hair = WHITE_HAIR
	elif roll < greying:
		look.hair = GREY_HAIR
	var style_roll := rng.next_float()
	match person.pronoun:
		"she":
			look.hair_style = Hair.LONG if style_roll < 0.5 else (Hair.BUN if style_roll < 0.7 else Hair.SHORT)
		"he":
			look.hair_style = Hair.SHORT if style_roll < 0.88 else Hair.LONG
		_:
			look.hair_style = Hair.SHORT if style_roll < 0.6 else (Hair.LONG if style_roll < 0.85 else Hair.BUN)
	if person.pronoun != "she" and rng.next_float() < 0.4 * smoothstep(32.0, 70.0, person.age):
		look.hair_style = Hair.BALD
	look.top = ArtStyle.mute(CASUAL_TOPS[rng.next_int(CASUAL_TOPS.size())], 0.55)
	look.work_top = ArtStyle.mute(WORK_TOPS.get(person.skill, CASUAL_TOPS[4]), 0.55)
	look.bottom = ArtStyle.mute(BOTTOMS[rng.next_int(BOTTOMS.size())], 0.55)
	_body(look, person.pronoun, person.age, rng)
	return look


## Body type, a woman's figure and what covers the legs.
static func _body(look: FigureLook, pronoun: String, age: int, rng: CellRandom) -> void:
	var roll := rng.next_float()
	if age < 14:
		look.build = Build.SLIM if roll < 0.4 else (Build.AVERAGE if roll < 0.85 else Build.STOCKY)
	else:
		# Heavier bodies become more common through middle age.
		var heavy := 0.1 + 0.18 * smoothstep(25.0, 55.0, age)
		var athletic := 0.2 - 0.12 * smoothstep(30.0, 65.0, age)
		if roll < 0.22:
			look.build = Build.SLIM
		elif roll < 0.22 + athletic:
			look.build = Build.ATHLETIC
		elif roll < 0.22 + athletic + 0.14:
			look.build = Build.STOCKY
		elif roll < 0.22 + athletic + 0.14 + heavy:
			look.build = Build.HEAVY
		else:
			look.build = Build.AVERAGE
	look.girth = clampf(look.girth, 0.92, 1.12)
	match look.build:
		Build.SLIM:
			look.girth *= 0.84
			look.limbs = 0.84
			look.shoulders *= 0.95
			look.waist = 0.9
		Build.ATHLETIC:
			look.girth *= 0.95
			look.limbs = 1.12
			look.shoulders *= 1.1
			look.waist = 0.86
		Build.STOCKY:
			look.girth *= 1.12
			look.limbs = 1.16
			look.shoulders *= 1.07
			look.height *= 0.97
		Build.HEAVY:
			look.girth *= 1.28
			look.limbs = 1.22
			look.waist = 1.16
			look.belly = rng.range_float(0.55, 1.0)
	var feminine := pronoun == "she"
	if feminine:
		look.waist *= 0.86
		look.hips *= 1.06
		look.bust = rng.range_float(0.6, 1.0) * smoothstep(11.0, 16.0, age) * (1.3 if look.build == Build.HEAVY else 1.0)
	elif pronoun != "he":
		look.waist *= 0.94
	var g := rng.next_float()
	if feminine and age >= 4:
		look.garment = Garment.TROUSERS if g < 0.5 else (Garment.SKIRT if g < 0.78 else Garment.DRESS)
	elif pronoun != "he" and age >= 14 and g < 0.15:
		look.garment = Garment.SKIRT
	look.legwear = look.skin if rng.next_float() < 0.4 else TIGHTS[rng.next_int(TIGHTS.size())]


## A plain adult for figures without a resident (gang members, wardens, passengers).
static func generic(key: String) -> FigureLook:
	var look := FigureLook.new()
	var h := key.hash()
	var rng := CellRandom.new(h)
	look.height = rng.range_float(1.66, 1.86)
	look.shoulders = rng.range_float(1.0, 1.1)
	look.skin = SKIN[rng.next_int(SKIN.size())]
	look.hair = HAIR[rng.next_int(HAIR.size())]
	look.hair_style = Hair.SHORT if rng.next_int(3) > 0 else Hair.BALD
	look.top = ArtStyle.mute(CASUAL_TOPS[rng.next_int(CASUAL_TOPS.size())], 0.55)
	look.work_top = look.top
	look.bottom = ArtStyle.mute(BOTTOMS[rng.next_int(BOTTOMS.size())], 0.55)
	# A third of the figures without a resident are women.
	var pronoun := "she" if rng.next_float() < 0.35 else "he"
	if pronoun == "she":
		look.height -= 0.12
		look.shoulders *= 0.9
		look.hips = 1.06
		if look.hair_style == Hair.BALD:
			look.hair_style = Hair.BUN
	_body(look, pronoun, 35, rng)
	look.garment = Garment.TROUSERS
	return look
