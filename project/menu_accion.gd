extends Control

# Referencias a los elementos de la interfaz
@onready var margins = $MarginContainer
@onready var main_column = $MarginContainer/VBoxContainer
@onready var title_label = $MarginContainer/VBoxContainer/Label
@onready var actions_column = $MarginContainer/VBoxContainer/VBoxContainer
@onready var solution_button = $MarginContainer/VBoxContainer/VBoxContainer/SolucionOptima
@onready var back_button = $MarginContainer/VBoxContainer/FilaInferior/BtnAtras

func _ready() -> void:
	# Se actualiza la interfaz cuando cambia el tamaño
	resized.connect(_on_menu_resized)
	_update_layout()

func _on_menu_resized() -> void:
	# Se espera a que los contenedores puedan reorganizar los elementos
	_update_layout.call_deferred()

func _update_layout() -> void:
	if not is_node_ready():
		return
	
	# Se usa el lado más corto como referencia para mantener las proporciones
	var base_size = minf(size.x, size.y)
	var margin = roundi(base_size * 0.04)
	var separation = roundi(base_size * 0.03)
	
	# Se calculan los márgenes respecto a los bordes de la pantalla
	for side in ["left", "top", "right", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, margin)
	
	margins.add_theme_constant_override("margin_top", roundi(size.y * 0.08))
	main_column.add_theme_constant_override("separation", separation)
	
	# El título puede ocupar más de una línea en pantallas estrechas
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", maxi(1, roundi(base_size * 0.045)))

	# Se centran las opciones en el espacio entre el título y Atrás
	actions_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_column.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Se adapta el botón prinicipal al acho disponible y se centra
	var available_width = maxf(0.0, size.x - margin * 2.0)
	solution_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	solution_button.custom_minimum_size = Vector2(
		minf(available_width, base_size * 0.65),
		base_size * 0.13
	)
	solution_button.add_theme_font_size_override("font_size", maxi(1, roundi(base_size * 0.035)))
	
	# Se mantiene el botón Atrás con un tamaño proporcional al resto
	back_button.custom_minimum_size = Vector2(base_size * 0.24, base_size * 0.1)
	back_button.add_theme_font_size_override("font_size", maxi(1, roundi(base_size * 0.032)))

func _process(delta: float) -> void:
	pass


func _on_solucion_optima_pressed() -> void:
	get_tree().change_scene_to_file("res://node_2d.tscn")


func _on_btn_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://menu_principal.tscn")
