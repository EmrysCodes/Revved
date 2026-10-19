extends RefCounted
const GOLD:=Color("ffd05d")
const CYAN:=Color("4ee5ef")
const INK:=Color("0d151e")
const PANEL:=Color("13232e")
static func box(color:Color,border:=Color.TRANSPARENT,radius:=6,width:=0) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=color;style.border_color=border
	style.set_corner_radius_all(radius);style.set_border_width_all(width)
	style.content_margin_left=18;style.content_margin_right=18;style.content_margin_top=11;style.content_margin_bottom=11
	return style
static func make() -> Theme:
	var theme:=Theme.new();theme.default_font_size=19
	var condensed:=FontVariation.new();condensed.base_font=ThemeDB.fallback_font;condensed.variation_embolden=.35;condensed.variation_transform=Transform2D(Vector2(.90,0),Vector2(0,1),Vector2.ZERO);theme.default_font=condensed
	if ResourceLoader.exists("res://assets/fonts/BarlowCondensed-SemiBold.ttf"):
		theme.default_font=load("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
	for type in ["Button","OptionButton","MenuButton"]:
		theme.set_stylebox("normal",type,box(Color("172a36"),Color("2d4553"),5,1))
		theme.set_stylebox("hover",type,box(Color("274452"),GOLD,5,1))
		theme.set_stylebox("pressed",type,box(GOLD,GOLD,5,1))
		theme.set_stylebox("disabled",type,box(Color("111e27"),Color("263742"),5,1))
		theme.set_stylebox("focus",type,box(Color.TRANSPARENT,GOLD,5,3))
		theme.set_color("font_color",type,Color("edf3f4"))
		theme.set_color("font_hover_color",type,Color.WHITE)
		theme.set_color("font_pressed_color",type,INK)
		theme.set_color("font_disabled_color",type,Color("708693"))
		theme.set_font_size("font_size",type,20)
		theme.set_constant("outline_size",type,0)
	theme.set_stylebox("panel","PanelContainer",box(PANEL,Color("304954"),10,1))
	theme.set_stylebox("tab_selected","TabBar",box(GOLD,GOLD,4,1))
	theme.set_stylebox("tab_unselected","TabBar",box(Color("172a36"),Color("304954"),4,1))
	theme.set_color("font_selected_color","TabBar",INK);theme.set_color("font_unselected_color","TabBar",Color("c2d0d7"))
	theme.set_stylebox("normal","LineEdit",box(Color("0a151e"),Color("50707e"),5,1))
	theme.set_stylebox("focus","LineEdit",box(Color("142633"),GOLD,5,2))
	theme.set_color("font_color","LineEdit",Color.WHITE)
	theme.set_stylebox("panel","PopupMenu",box(INK,Color("50707e"),6,1))
	theme.set_stylebox("hover","PopupMenu",box(Color("2b4654"),GOLD,3,1))
	theme.set_color("font_color","PopupMenu",Color.WHITE)
	theme.set_stylebox("scroll","VScrollBar",box(Color("12232c"),Color.TRANSPARENT,4))
	for state in ["scroll","grabber","grabber_highlight","grabber_pressed"]:
		var slim:=box(Color("3b5868") if state!="scroll" else Color("101d27"),Color.TRANSPARENT,3)
		slim.content_margin_left=4;slim.content_margin_right=4;slim.content_margin_top=4;slim.content_margin_bottom=4
		theme.set_stylebox(state,"VScrollBar",slim)
	
	
	theme.set_stylebox("slider","HSlider",box(Color("263f4c"),Color.TRANSPARENT,3))
	theme.set_stylebox("grabber_area","HSlider",box(GOLD,Color.TRANSPARENT,3))
	theme.set_color("font_color","Label",Color("edf1f2"))
	return theme
static func apply(control:Control) -> void:
	control.theme=make()
	var audio:=Node.new();audio.name="MenuAudio";audio.set_script(load("res://ui/menu_audio.gd"));control.add_child(audio)
