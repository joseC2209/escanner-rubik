extends CanvasLayer

# Icono para el botón de Inicio
const HOME_ICON = preload("res://iconos/inicio.svg")

# Botón común para regresar al menú principal
@onready var home_button = $ContenedorInicio/BtnInicio

func _ready() -> void:
	home_button.pressed.connect(on_home_button_pressed)
	
	# Se coloca la casa en el centro y se permite adaptar su tamaño
	home_button.icon = HOME_ICON
	home_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	home_button.expand_icon = true
	
	# Se adapta el botón al iniciar y cuando cambia la pantalla
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()
	
	# Se oculta inicialmente hasta conocer la pantalla activa
	home_button.hide()
	
	# Se actualiza la visibilidad en cada cambio de escena
	get_tree().scene_changed.connect(_update_visibility)
	_update_visibility.call_deferred()

func _update_layout() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var base_size = minf(screen_size.x, screen_size.y)
	
	# Se calcula un botón cuadrado usando el lado más corto de la pantalla
	var diameter = base_size * 0.11
	
	# El icono ocupa la mitad del diámetro para dejar espacio
	home_button.add_theme_constant_override("icon_max_width", roundi(diameter * 0.50))
	
	home_button.custom_minimum_size = Vector2(diameter, diameter)
	home_button.size = Vector2(diameter, diameter)
	
	# Se separa el botón de los bordes superior y derecho
	var side_margin = base_size * 0.06
	var top_margin = screen_size.y * 0.04
	
	home_button.offset_left = -side_margin - diameter
	home_button.offset_right = -side_margin
	home_button.offset_top = top_margin
	home_button.offset_bottom = top_margin + diameter
	
	# Se adapta el borde y curvatura al diámetro del botón
	var border_width = maxi(1, roundi(diameter * 0.04))
	var corner_radius = ceili(diameter / 2.0)
	
	# Se mantiene la forma circular en los distintos estados del botón
	for state in ["normal", "hover", "pressed"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#0000a7")
		style.border_color = Color("091326")
		style.set_border_width_all(border_width)
		style.set_corner_radius_all(corner_radius)
		
		home_button.add_theme_stylebox_override(state, style)

func _update_visibility() -> void:
	var current_scene = get_tree().current_scene
	
	# Se permite volver a utilizar el botón tras finalizar el cambio de escena
	home_button.disabled = false
	
	# Se muestra el icono de inicio solo cuando hay otra pantalla
	home_button.visible = (
		current_scene != null and
		current_scene.scene_file_path!= "res://menu_principal.tscn" and 
		current_scene.scene_file_path != "res://pantalla_carga.tscn")

func on_home_button_pressed() -> void:
	# Se impiden nuevas pulsaciones mientras se cambia de pantalla
	home_button.disabled = true
	
	# Se regresa al menú principal y se comprueba que se pueda cargar
	var error = get_tree().change_scene_to_file("res://menu_principal.tscn")
	
	if error != OK:
		home_button.disabled = false
		push_error("No se ha podido cargar el menú principal: " + error_string(error))

func _process(delta: float) -> void:
	pass
