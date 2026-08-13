class_name UiKit
extends RefCounted
## Shared UI builder toolkit (CRITIQUE C3 — decomposing the Hud god-object). Pure, static
## factory functions for the gilded panels, styled labels, buttons, and gauges the HUD and
## its sub-screens are assembled from. No instance state: everything comes from parameters,
## Palette constants, and Loc — so any script (HUD, menus, future panels) can build a
## consistent widget without a Hud reference. Extracted verbatim from hud.gd.

# Every decorative control must let the pointer through, or it eats the LMB swing.
static func ignore(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

# A localized, outlined label — the single construction point where UI text is translated.
static func label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = Loc.t(text)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Palette.UI_BG.r, Palette.UI_BG.g, Palette.UI_BG.b, 0.82)
	sb.set_border_width_all(2)
	sb.border_color = Palette.UI_EDGE
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 11
	sb.content_margin_right = 11
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	return sb

static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style())
	ignore(p)
	return p

static func menu_style() -> StyleBoxFlat:
	var sb := panel_style()
	sb.bg_color = Color(Palette.UI_BG.r, Palette.UI_BG.g, Palette.UI_BG.b, 0.96)
	sb.set_border_width_all(3)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb

static func trough_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.set_border_width_all(1)
	sb.border_color = Palette.UI_EDGE_D
	sb.set_corner_radius_all(4)
	return sb

static func button_style(hot: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.UI_BG2 if hot else Color(Palette.UI_BG.r, Palette.UI_BG.g, Palette.UI_BG.b, 0.9)
	sb.set_border_width_all(2)
	sb.border_color = Palette.UI_EDGE if hot else Palette.UI_EDGE_D
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	return sb

static func pip_style(filled: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(4)
	if filled:
		sb.bg_color = Palette.UI_HP
		sb.set_border_width_all(1)
		sb.border_color = Palette.GOLD_L
	else:
		sb.bg_color = Color(Palette.UI_HP_D.r, Palette.UI_HP_D.g, Palette.UI_HP_D.b, 0.7)
		sb.set_border_width_all(1)
		sb.border_color = Color(0, 0, 0, 0.6)
	return sb
