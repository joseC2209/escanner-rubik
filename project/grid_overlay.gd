extends Control

# Configuración de la cuadrícula del cubo 2x2x2
var grid_size : int = 2
var square_size : float = 140.0 # Tamaño de cada cuadradito en píxeles
var line_thickness : float = 4.0
var grid_color : Color = Color(0.2, 0.8, 0.2, 0.8)

# Called when the node enters the scene tree for the first time.
func _ready():
	# El nodo se redibuja si la ventana cambia de tamaño
	get_tree().get_root().size_changed.connect(queue_redraw)
	
func _draw():
	# Calcula el ancho y alto total de la cuadrícula 2x2
	var total_width = grid_size * square_size
	var total_height = grid_size * square_size
	
	# Calcula la esquina superior izquierda para que quede justo en el centro de la pantalla
	var start_x = (size.x - total_width) / 2.0
	var start_y = (size.y - total_height) / 2.0
	
	# Dibuja los 4 cuadrados
	for row in range(grid_size):
		for col in range(grid_size):
			# Calcula la coordinada de cada cuadradito
			var x = start_x + (col * square_size)
			var y = start_y + (row * square_size)
			
			# Define el rectángulo
			var rect = Rect2(x, y, square_size, square_size)
			
			# Dibujado vacío y con el grosor de línea que especificamos
			draw_rect(rect, grid_color, false, line_thickness)
			
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
