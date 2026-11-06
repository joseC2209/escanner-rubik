extends Control

# Referencias a los contenedors y al título del menú
@onready var grid = $MarginContainer/VBoxContainer/GridContainer
@onready var margins = $MarginContainer
@onready var main_column = $MarginContainer/VBoxContainer
@onready var title_label = $MarginContainer/VBoxContainer/Label

func _ready () -> void:
	# Se detectan los cambios de tamaño u orientación de la ventana
	resized.connect(_on_menu_resized)
	# Se adapta la distribución al iniciarse el menú
	_update_layout()

func _on_menu_resized() -> void:
	# Se pospone el cálculo para que se aplique después del cambio
	_update_layout.call_deferred()

func _update_layout() -> void:
	var screen_size = get_viewport_rect().size
	
	# Se usa el lado más corto como referencia para mantener las proporciones
	var base_size = minf(screen_size.x, screen_size.y)
	var margin = roundi(base_size * 0.04)
	
	# Se calculan los márgenes de los laterales e inferior
	for side in ["left", "right", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, margin)
	
	# Se separa el título del borde superior un 8% de la altura
	margins.add_theme_constant_override("margin_top", roundi(screen_size.y * 0.08))
	
	# Se adapta el título con el mismo criterio que en el menú de acciones
	title_label.add_theme_font_size_override("font_size", maxi(1, roundi(base_size * 0.045)))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Se calcula la separación entre el título y la cuadrícula de acciones
	main_column.add_theme_constant_override("separation", roundi(base_size * 0.03))
	
	# Se descuenta el espacio ocupado por los márgenes laterales
	var available_width = maxf(0.0, screen_size.x - margin * 2.0)
	
	# Se calcula el ancho según el lado más corto y el espacio suficiente
	var btn_width = minf(base_size * 0.40, available_width)
	
	# Se reserva más altura para mostrar la imagen y el texto debajo (20% más alto para dejar sitio al texto bajo la imagen)
	var btn_height = btn_width * 1.2 
	
	# Se calcula una separación proporcional entre los botones de acciones
	var separation = maxi(1, roundi(base_size * 0.03))
	
	# Se calcula cuántas columnas completas caben con las separaciones
	var columnas = maxi(1, floori((available_width + separation) / (btn_width + separation)))
	grid.columns = columnas
	
	# Se centra la cuadrícula en la pantalla
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", separation)
	grid.add_theme_constant_override("v_separation", separation)
	
	# Se aplica el tamaño a todos los botones de la cuadrícula
	for btn in grid.get_children():
		if btn is Button:
			btn.custom_minimum_size = Vector2(btn_width, btn_height)
			btn.add_theme_font_size_override("font_size", maxi(1, roundi(base_size * 0.032)))


func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menu_accion.tscn")
