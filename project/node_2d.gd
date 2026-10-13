extends Node2D

# Se obtiene la referencia al lienzo
@onready var camera_screeen = $CameraScreen

# Variable del escáner
var scanner : ScannerCore
# Sprite que muestra la imagen capturada dentro del juego
var camera_sprite: Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Se inicializa ScannerCore y se añade
	scanner = ScannerCore.new()
	add_child(scanner)
	
	# Comprueba que la clase C++ está disponible en Godot
	scanner.test_connection()
	
	# Encendido de la cámara a través de OpenCV
	scanner.open_camera()
	# Se usa un Sprite2D para mostrar el frame sin depender del tamaño mínimo del TextureRect
	camera_sprite = Sprite2D.new()
	camera_sprite.position = get_viewport_rect().size / 2.0
	camera_sprite.z_index = 10
	add_child(camera_sprite)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if scanner:
		# Se pide a C++ el fotograma actual de la webcam
		var img = scanner.get_frame()
		
		# Cada frame válido se convierte en una textura que Godot puede dibujar
		if img != null and not img.is_empty():
			# RGBA8 evita problemas de compatibilidad al subir texturas RGB8 a Vulkan
			img.convert(Image.FORMAT_RGBA8)
			
			# Se fuerza el dibujo por encima de otros nodos y con color neutro
			camera_screeen.visible = true
			camera_screeen.modulate = Color.WHITE
			camera_screeen.z_index = 10
			
			var texture = ImageTexture.create_from_image(img)
			camera_sprite.texture = texture
			
			var screen_size = get_viewport_rect().size
			var cam_size = Vector2(img.get_width(), img.get_height())
			
			# Se escala la imagen para cubrir todo el viewport del juego
			camera_sprite.scale = Vector2(get_viewport_rect().size.x / float(img.get_width()), get_viewport_rect().size.y / float(img.get_height()))

			# Se obtienen los rectángulos dibujados en la interfaz
			var ui_rects = $CanvasLayer/GridOverlay.get_grid_rects()
			var scaled_rects = []
			
			# Se calcula la proporción de pantalla a cámara
			var scale_x = cam_size.x / screen_size.x
			var scale_y = cam_size.y / screen_size.y
			
			# Se transforma cada rectángulo al tamaño real del fotograma de OpenCV
			for r in ui_rects:
				var scaled_x = r.position.x * scale_x
				var scaled_y = r.position.y * scale_y
				var scaled_w = r.size.x * scale_x
				var scaled_h = r.size.y * scale_y
				scaled_rects.append(Rect2(scaled_x, scaled_y, scaled_w, scaled_h))
				
			# Se envía a C++ para analizar los colores
			var colors = scanner.analyze_colors(scaled_rects)
			print(colors)
