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

# Máquina de estados para la UI
enum AppState{SCANNING, REVIEWING}
var current_state = AppState.SCANNING

# Ciclo de colores cuando el usuario vaya tocando la pantalla
var color_cycle = ["W", "G", "R", "B", "O", "Y"]

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
	# Se lee la cámara y analiza los colores si se está escaneando
	if scanner and current_state == AppState.SCANNING:
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
		# Se deshabilita el botón por seguridad antes del cambio
		capture_button.disabled = true
		
		# Se instancia el motor de resolución
		var solver = RubikSolver.new()
		# Se le inyecta la matriz de colores
		solver.load_from_colors(captured_faces)
		
		# Se calcula la solución
		var solucion = solver.solve()
		
		# Se guardan tanto la solución como el estado original para la escena 3D.
		Global.solucion_actual = solucion
		Global.colores_cubo = captured_faces.duplicate(true)
		
		# Se libera la cámara y se transiciona al visualizador 3D
		get_tree().change_scene_to_file("res://visualizador_3d.tscn")

func _on_capture_button_pressed() -> void:
	# Se asegura de que haya leído 4 colores y no se haya capturado nada vacío
	if current_scanned_colors.size() != 4 and captured_faces.size() >= 6:
		return
		
	if current_state == AppState.SCANNING:
		# Se congela la imagen para pasar al modo de revisión
		current_state = AppState.REVIEWING
		capture_button.text = "Confirmar"
		face_label.text = "Toca un color para corregirlo"
		
		# Cambios estéticos en la revisión
		camera_sprite.visible = false # Se oculta la cámara
		# Se pone el fondo gris oscuro
		camera_screeen.modulate = Color(0.15, 0.15, 0.15)
		# Se vuelve a colores opacos
		$CanvasLayer/GridOverlay.set_review_mode(true)
		
	elif current_state == AppState.REVIEWING:
		# Se guarda una copia del array
		captured_faces.append(current_scanned_colors.duplicate())
		current_state = AppState.SCANNING
		capture_button.text = "Capturar cara"
		
		# Se vuelve a la estética de escaneo
		camera_sprite.visible = true # Se devuelve la cámara
		# El fondo se restaura solo en el _process() pero se le avisa a la grid
		$CanvasLayer/GridOverlay.set_review_mode(false)
		
		update_ui_text()

# Detecta los toques en la pantalla para cambiar el color manualmente
func _input(event: InputEvent) -> void:
	# Si el cubo está completado, se ignoran los toques
	if captured_faces.size() >= 6 or current_state != AppState.REVIEWING:
		return
	
	var is_click = (event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT)
	var is_touch = (event is InputEventScreenTouch and event.is_pressed())
	
	if is_click or is_touch:
		var touch_pos = event.position
		var ui_rects = $CanvasLayer/GridOverlay.get_grid_rects()
		
		# Se comprueba si el toque ha sido en alguno de los 4 cuadraditos
		for i in range(ui_rects.size()):
			if ui_rects[i].has_point(touch_pos):
				# Se encuentra el color actual y se pasa al siguiente según el ciclo
				var current_c = current_scanned_colors[i]
				var idx = color_cycle.find(current_c)
				if idx == -1: idx = 0
				
				var next_c = color_cycle[(idx + 1) % color_cycle.size()]
				
				# Como la cámara está en pausa, se modifica el color directamente
				current_scanned_colors[i] = next_c
				
				# Se fuerza el redibujado visual instantáneamente
				$CanvasLayer/GridOverlay.update_detected_colors(current_scanned_colors)
				
				# Se marca el evento como "consumido" para que Godot no haga clics dobles
				get_viewport().set_input_as_handled()
				break
