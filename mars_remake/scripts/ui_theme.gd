class_name MarsUI
extends RefCounted

const VOID := Color("05080b")
const SPACE := Color("081017")
const HULL := Color("111a20")
const HULL_RAISED := Color("18252c")
const STEEL := Color("33454d")
const TEXT := Color("e6edf0")
const MUTED := Color("94a7ad")
const CYAN := Color("79ced2")
const CYAN_DIM := Color("315e63")
const MARS := Color("a84c2f")
const MARS_DARK := Color("56271f")
const AMBER := Color("f0b35c")
const DANGER := Color("ef705f")
const SUCCESS := Color("80c59b")


static func make_theme() -> Theme:
	var theme := Theme.new()
	var body_font := SystemFont.new()
	body_font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC"])
	var data_font := SystemFont.new()
	data_font.font_names = PackedStringArray(["Bahnschrift", "DIN Alternate", "Microsoft YaHei UI"])
	theme.default_font = body_font
	theme.default_font_size = 18
	theme.set_font("font", "Button", body_font)
	theme.set_font("font", "LineEdit", body_font)
	theme.set_font("font", "Label", body_font)
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color("647178"))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("caret_color", "LineEdit", CYAN)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_constant("outline_size", "Label", 1)
	theme.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.48))
	theme.set_stylebox("normal", "Button", panel(HULL_RAISED, STEEL, 4, 1, 18))
	theme.set_stylebox("hover", "Button", panel(Color("20323a"), CYAN, 4, 2, 18))
	theme.set_stylebox("pressed", "Button", panel(Color("29383c"), AMBER, 4, 2, 18))
	theme.set_stylebox("focus", "Button", panel(Color("17272e"), CYAN, 4, 3, 18))
	theme.set_stylebox("disabled", "Button", panel(Color("0c1216"), Color("273238"), 4, 1, 18))
	theme.set_stylebox("normal", "LineEdit", panel(Color("091116"), STEEL, 3, 2, 16))
	theme.set_stylebox("focus", "LineEdit", panel(Color("091116"), CYAN, 3, 3, 16))
	theme.set_stylebox("normal", "ProgressBar", panel(Color("081014"), Color("2b3940"), 2, 1, 2))
	theme.set_stylebox("fill", "ProgressBar", panel(CYAN, CYAN, 2, 0, 2))
	theme.set_font("font", "TelemetryLabel", data_font)
	return theme


static func panel(background: Color, border: Color, radius := 4, border_width := 1, padding := 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


static func data_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Bahnschrift", "DIN Alternate", "Microsoft YaHei UI"])
	return font


static func body_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC"])
	return font
