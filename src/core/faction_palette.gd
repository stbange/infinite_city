class_name FactionPalette
extends RefCounted
## Faction colours as shown (spec release-candidate / Accessibility): with the colour-blind option,
## each colour becomes the nearest of a palette that stays distinct for common colour blindness
## (Okabe and Ito).

const SAFE: Array[Color] = [
	Color(0.9, 0.6, 0.0), Color(0.34, 0.71, 0.91), Color(0.0, 0.62, 0.45), Color(0.94, 0.89, 0.26),
	Color(0.0, 0.45, 0.7), Color(0.84, 0.37, 0.0), Color(0.8, 0.47, 0.65), Color(0.95, 0.95, 0.95),
]

static var colorblind: bool = false


static func display(color: Color) -> Color:
	if not colorblind:
		return color
	var best := SAFE[0]
	var best_d := INF
	for c in SAFE:
		var d := Vector3(c.r - color.r, c.g - color.g, c.b - color.b).length_squared()
		if d < best_d:
			best_d = d
			best = c
	return best
