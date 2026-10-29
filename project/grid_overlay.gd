extends Control

# Configuración de la cuadrícula del cubo 2x2x2
var grid_size : int = 2
var square_size : float = 260.0 # Tamaño de cada cuadradito en píxeles
var line_thickness : float = 4.0
var grid_color : Color = Color.BLACK
var current_colors : Array = [] # Guarda las letras detectadas

# Controla si está en la pantalla de revisión
var is_reviewing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# El nodo se redibuja si la ventana cambia de tamaño
	get_tree().get_root().size_changed.connect(queue_redraw)

func update_detected_colors(colors: Array):
	current_colors = colors
	queue_redraw()
	
# Cambia el estado visual de la cuadrícula
func set_review_mode(reviewing: bool):
	is_reviewing = reviewing
	queue_redraw()
	
func get_color_from_char(c: String) -> Color:
	# Si se está revisando, color opaco (1.0). Si se está escaneando, color translúcido (0.4)
	var alpha = 1.0 if is_reviewing else 0.4
	match c:
		"R": return Color(1.0, 0.1, 0.1, alpha) # Rojo
		"G": return Color(0.1, 1.0, 0.1, alpha) # Verde
		"B": return Color(0.1, 0.1, 1.0, alpha) # Azul
		"Y": return Color(1.0, 0.9, 0.1, alpha) # Amarillo
		"O": return Color(1.0, 0.5, 0.1, alpha) # Naranja
		"W": return Color(1.0, 1.0, 1.0, alpha) # Blanco
		_: return Color (0.0, 0.0, 0.0) # Si no hay ningún color (error), transparente
	
func _draw():
	# Calcula el ancho y alto total de la cuadrícula 2x2
	var total_width = grid_size * square_size
	var total_height = grid_size * square_size
	
	# Calcula la esquina superior izquierda para que quede justo en el centro de la pantalla
	var start_x = (size.x - total_width) / 2.0
	var start_y = (size.y - total_height) / 2.0
	
	var index = 0 # Para recorrer el array de colores escaneados
	
	# Dibuja los 4 cuadrados
	for row in range(grid_size):
		for col in range(grid_size):
			# Calcula la coordinada de cada cuadradito
			var x = start_x + (col * square_size)
			var y = start_y + (row * square_size)
			
			# Define el rectángulo
			var rect = Rect2(x, y, square_size, square_size)
			
			# Si hay colores escaneados, se rellena el fondo
			if current_colors.size() > index:
				var fill_color = get_color_from_char(current_colors[index])
				draw_rect(rect, fill_color, true)
			
			# Dibujado vacío y con el grosor de línea que especificamos
			draw_rect(rect, grid_color, false, line_thickness)
			index += 1
			
func get_grid_rects() -> Array:
	var rects = []
	var total_width = grid_size * square_size
	var total_height = grid_size * square_size
	
	var start_x = (size.x - total_width) / 2.0
	var start_y = (size.y - total_height) / 2.0
	
	for row in range(grid_size):
		for col in range(grid_size):
			var x = start_x + (col * square_size)
			var y = start_y + (row * square_size)
			rects.append(Rect2(x, y, square_size, square_size))
			
	return rects


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
