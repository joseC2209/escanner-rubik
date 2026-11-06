extends RefCounted
class_name EstilosBotones

# Colores del texto para los botones azules de la aplicación
const BLUE_TEXT_COLORS = {
	"font_color": Color("#6c9bff"),
	"font_focus_color": Color("#6c9bff"),
	"font_pressed_color": Color("#6c9bff"),
	"font_hover_color": Color("#3e78ff"),
	"font_hover_pressed_color": Color("#3e78ff"),
	"font_disabled_color": Color("#013ced")
}

# Colores del texto para retroceder en la solución
const PREVIOUS_TEXT_COLORS = {
	"font_color": Color("#ff6d5b"),
	"font_focus_color": Color("#ff6d5b"),
	"font_pressed_color": Color("#ff6d5b"),
	"font_hover_color": Color("#ff3b2c"),
	"font_hover_pressed_color": Color("#ff3b2c"),
	"font_disabled_color": Color("#ce0c00")
}

# Colores del texto para avanzar en la solución
const NEXT_TEXT_COLORS = {
	"font_color": Color("#47ff41"),
	"font_focus_color": Color("#47ff41"),
	"font_pressed_color": Color("#47ff41"),
	"font_hover_color": Color("#00ee02"),
	"font_hover_pressed_color": Color("#00ee02"),
	"font_disabled_color": Color("#009201")
}

static func aplicar_colores_texto(button: Button, colors: Dictionary) -> void:
	# Se aplica el color correspondiente a cada estado del texto
	for property_name in colors:
		button.add_theme_color_override(property_name, colors[property_name])

static func crear_fondo(background: Color, radius: float, scale_factor: float, border_width: float = 0.0) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background
	
	# Se escalan las esquinas y el borde según el tamaño de pantalla
	style.set_corner_radius_all(maxi(1, roundi(radius * scale_factor)))
	style.corner_detail = 8
	style.set_border_width_all(roundi(border_width * scale_factor))
	style.border_color = Color("#091225")
	
	# Se mantiene la proporción de los márgenes interiores originales
	style.content_margin_left = 20.0 * scale_factor
	style.content_margin_right = 20.0 * scale_factor
	style.content_margin_top = 10.0 * scale_factor
	style.content_margin_bottom = 10.0 * scale_factor
	
	return style

static func aplicar_estilo_azul(button: Button, base_size: float, is_option: bool = false) -> void:
	# Se adaptan las medidas originales tomando 648 como altura de referencia
	var scale_factor = base_size / 648.0
	
	# Las opciones utilizan esquinas de 16 y borde de 4
	var radius = 16.0 if is_option else 20.0
	var border_width = 4.0 if is_option else 0.0
	
	aplicar_colores_texto(button, BLUE_TEXT_COLORS)
	
	# Se crea un estilo independiente para cada estado del botón
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style = crear_fondo(Color("#0000a7"), radius, scale_factor, border_width)
		button.add_theme_stylebox_override(state, style)

static func aplicar_estilo_navegacion(button: Button, base_size: float, is_previous: bool) -> void:
	var scale_factor = base_size / 648.0
	
	# Se selecciona la paleta según la dirección de navegación
	var text_colors = PREVIOUS_TEXT_COLORS if is_previous else NEXT_TEXT_COLORS
	var background = Color("#ab0000") if is_previous else Color("#00a700")
	var disabled_background = Color("#460000") if is_previous else Color("#002a00")
	
	aplicar_colores_texto(button, text_colors)
	
	# Se usa un fondo más oscuro si está desactivado
	for state in ["normal", "hover", "pressed", "disabled"]:
		var state_background = disabled_background if state == "disabled" else background
		var style = crear_fondo(state_background, 20.0, scale_factor)
		button.add_theme_stylebox_override(state, style)
