extends Node2D

# Se obtiene la referencia al lienzo
@onready var camera_screeen = $CameraScreen

# Variable del escáner
var scanner : ScannerCore
# Sprite que muestra la imagen capturada dentro del juego
var camera_sprite: Sprite2D

# Variables para la interfaz y estado del cubo
@onready var face_label = $CanvasLayer/FaceLabel
@onready var capture_button = $CanvasLayer/CaptureButton

var captured_faces : Array = []
var current_scanned_colors : Array = []

# Orden estándar de la captura de las cara, asumiendo BLANCO arriba y VERDE al frente
var faces_names = [
	"SUPERIOR (Blanca)",
	"FRONTAL (Verde)",
	"DERECHA (Roja)",
	"TRASERA (Azul)",
	"IZQUIERDA (Naranja)",
	"INFERIOR (Amarilla)"
]

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
	
	update_ui_text()


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
			current_scanned_colors = scanner.analyze_colors(scaled_rects)
			
			# Se envían los colores detectados a la interfaz para que los pinte
			$CanvasLayer/GridOverlay.update_detected_colors(current_scanned_colors)

# Se actualiza el texto superior según la cara que estemos escaneando
func update_ui_text():
	if captured_faces.size() < 6:
		face_label.text = "Escanea la cara: " + faces_names[captured_faces.size()]
	else:
		face_label.text = "¡Cubo completado!"
		capture_button.disabled = true
		
		# Se instancia el motor de resolución
		var solver = RubikSolver.new()
		# Se le inyecta la matriz de colores
		solver.load_from_colors(captured_faces)
		
		# Se imprime la solución
		var solucion = solver.solve()
		print("LA SOLUCIÓN ES: ", solucion)
		face_label.text = "Solución " + solucion

func _on_capture_button_pressed() -> void:
	# Se asegura de que haya leído 4 colores y no se haya capturado nada vacío
	if current_scanned_colors.size() == 4 and captured_faces.size() < 6:
		# Se guarda una copia del array
		captured_faces.append(current_scanned_colors.duplicate())
		print("Cara guardada: ", current_scanned_colors)
		update_ui_text()
