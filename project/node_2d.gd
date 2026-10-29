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
@onready var grid_overlay = $CanvasLayer/GridOverlay

# Referencia al nodo del plugin NativeCamera de Android
@onready var android_camera = $AndroidCamera

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

# Variables para Android
var is_android : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_android = (OS.get_name() == "Android")
	
	# Se inicializa ScannerCore y se añade
	scanner = ScannerCore.new()
	add_child(scanner)
	scanner.test_connection()

	# Se crea el nodo que mostrará el vídeo de la cámara.
	camera_sprite = Sprite2D.new()
	camera_sprite.position = get_viewport_rect().size / 2.0
	camera_sprite.z_index = 10
	add_child(camera_sprite)
	
	# El fondo gris debe estar oculto al principio
	camera_screeen.visible = false
	
	if is_android:
		# Configuración Android
		capture_button.size = Vector2(340, 100)
		capture_button.position.x = (get_viewport_rect().size.x - capture_button.size.x) / 2.0
		capture_button.position.y = get_viewport_rect().size.y - 250
		
		face_label.position.x = (get_viewport_rect().size.x - face_label.size.x) / 2.0
		face_label.position.y = 180
		
		grid_overlay.square_size = 260.0
		
		# Nos aseguramos de conectar las señales del plugin
		if not android_camera.camera_permission_granted.is_connected(_on_android_camera_camera_permission_granted):
			android_camera.camera_permission_granted.connect(_on_android_camera_camera_permission_granted)
		if not android_camera.camera_permission_denied.is_connected(_on_android_camera_camera_permission_denied):
			android_camera.camera_permission_denied.connect(_on_android_camera_camera_permission_denied)
		if not android_camera.frame_available.is_connected(_on_android_camera_frame_available):
			android_camera.frame_available.connect(_on_android_camera_frame_available)

		# Se verifican permisos a través de la API del plugin
		if android_camera.has_camera_permission():
			iniciar_camara_android()
		else:
			android_camera.request_camera_permission()
		
	else:
		# Configuración Windows
		capture_button.position.y = 548
		capture_button.size = Vector2(258, 80)
		face_label.position.y = 32
		grid_overlay.square_size = 140.0

		# Encendido de la cámara a través de OpenCV en Windows.
		scanner.open_camera()
		update_ui_text()

# Señal conectada desde el nodo NativeCamera. Se dispara si el usuario pulsa "Permitir"
func _on_android_camera_camera_permission_granted() -> void:
	iniciar_camara_android()

# Señal conectada desde el nodo NativeCamera. Se dispara si el usuario rechaza el permiso
func _on_android_camera_camera_permission_denied() -> void:
	pass # Omitido para mantener la UI limpia
	
func iniciar_camara_android() -> void:
	# Verificamos si el plugin está registrado en el motor para Android
	if not Engine.has_singleton("NativeCameraPlugin"):
		return

	var cameras = android_camera.get_all_cameras()
	
	if cameras.size() > 0:
		# Buscamos preferentemente la cámara trasera para el escaneo del cubo
		var target_camera : CameraInfo = null
		for cam in cameras:
			if not cam.is_front_facing():
				target_camera = cam
				break
		# Si no se encuentra trasera explícita, usamos la primera que exista
		if target_camera == null:
			target_camera = cameras[0]

		var target_camera_id: String = target_camera.get_camera_id()
		
		# Seleccionamos una resolución compatible garantizada desde los output_sizes del sensor
		var supported_sizes = target_camera.get_output_sizes()
		var chosen_w = 640
		var chosen_h = 480
		
		if supported_sizes.size() > 0:
			var matched = false
			# Primera preferencia: 640x480 para fluidez en tiempo real
			for s in supported_sizes:
				if (s.get_width() == 640 and s.get_height() == 480) or (s.get_width() == 480 and s.get_height() == 640):
					chosen_w = s.get_width()
					chosen_h = s.get_height()
					matched = true
					break
			# Segunda preferencia: 1280x720
			if not matched:
				for s in supported_sizes:
					if (s.get_width() == 1280 and s.get_height() == 720) or (s.get_width() == 720 and s.get_height() == 1280):
						chosen_w = s.get_width()
						chosen_h = s.get_height()
						matched = true
						break
			# Si ninguna de esas exactas existe, tomamos una soportada intermedia
			if not matched:
				for s in supported_sizes:
					if s.get_width() <= 1280 and s.get_width() >= 480:
						chosen_w = s.get_width()
						chosen_h = s.get_height()
						matched = true
						break
			if not matched:
				chosen_w = supported_sizes[0].get_width()
				chosen_h = supported_sizes[0].get_height()

		# Se prepara la petición configurando la cámara seleccionada
		var request = android_camera.create_feed_request()
		request.set_camera_id(target_camera_id)
		request.set_width(chosen_w)
		request.set_height(chosen_h)
		# Se desactiva el salto de frames para recibir el flujo en tiempo real (30 fps)
		request.set_frames_to_skip(0)
		# Se activa auto_upright para que la orientación del fotograma se adapte al móvil en vertical
		request.set_auto_upright(true)
			
		# Arrancamos hardware
		android_camera.start(request)

# Señal conectada desde NativeCamera
func _on_android_camera_frame_available(frame) -> void:
	if current_state != AppState.SCANNING:
		return
		
	# Comprobación de seguridad: evitamos cuelgues si el plugin cambia su API
	if not frame.has_method("get_image"):
		return
		
	var img = frame.get_image() 
	
	# Si la cámara está arrancando, puede devolver frames vacíos. Ignoramos silenciosamente.
	if img == null or img.is_empty():
		return
		
	# Si tenemos imagen válida, la procesamos
	procesar_fotograma_para_colores(img)
	
	# Aseguramos que el texto esté correcto una vez tenemos frames
	if face_label.text.is_empty() or not face_label.text.begins_with("Escanea"):
		update_ui_text()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_android and scanner and current_state == AppState.SCANNING:
		# En Windows se usa OpenCV nativo directo
		var img = scanner.get_frame()
		if img != null and not img.is_empty():
			procesar_fotograma_para_colores(img)

func procesar_fotograma_para_colores(img: Image) -> void:
	if img.get_width() == 0 or img.get_height() == 0:
		return
		
	img = img.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	
	# Nos aseguramos de no dibujar un panel gris encima del vídeo
	camera_screeen.visible = false
	
	var texture = ImageTexture.create_from_image(img)
	camera_sprite.texture = texture
				
	var screen_size = get_viewport_rect().size
	var cam_size = Vector2(img.get_width(), img.get_height())
	camera_sprite.scale = Vector2(screen_size.x / cam_size.x, screen_size.y / cam_size.y)
	camera_sprite.position = screen_size / 2.0

	# Se obtienen los rectángulos dibujados en la interfaz
	var ui_rects = grid_overlay.get_grid_rects()
	var scaled_rects = []
	var scale_x = cam_size.x / screen_size.x
	var scale_y = cam_size.y / screen_size.y
	
	for r in ui_rects:
		var scaled_x = r.position.x * scale_x
		var scaled_y = r.position.y * scale_y
		var scaled_w = r.size.x * scale_x
		var scaled_h = r.size.y * scale_y
		scaled_rects.append(Rect2(scaled_x, scaled_y, scaled_w, scaled_h))
		
	if is_android:
		# Se le pasas la imagen de Android a C++ para que OpenCV resuelva los colores
		current_scanned_colors = scanner.analyze_colors_from_image(img, scaled_rects)
	else:
		current_scanned_colors = scanner.analyze_colors(scaled_rects)
	
	grid_overlay.update_detected_colors(current_scanned_colors)

# Se actualiza el texto superior según la cara que estemos escaneando
func update_ui_text():
	if captured_faces.size() < 6:
		face_label.text = "Escanea la cara: " + faces_names[captured_faces.size()]
	else:
		capture_button.disabled = true
		
		# Apagamos hardware para ahorrar batería y recursos
		if is_android and android_camera != null:
			android_camera.stop()
			
		var solver = RubikSolver.new()
		solver.load_from_colors(captured_faces)
		var solucion = solver.solve()
		Global.solucion_actual = solucion
		Global.colores_cubo = captured_faces.duplicate(true)
		get_tree().change_scene_to_file("res://visualizador_3d.tscn")

func _on_capture_button_pressed() -> void:
	# Usamos "or" para impedir el avance si la lectura es nula o menor de 4
	if current_scanned_colors.size() != 4 or captured_faces.size() >= 6:
		return
		
	if current_state == AppState.SCANNING:
		current_state = AppState.REVIEWING
		capture_button.text = "Confirmar"
		face_label.text = "Toca un color para corregirlo"
		
		# Cambios estéticos en la revisión
		camera_sprite.visible = false 
		camera_screeen.visible = true # Activamos el fondo gris para el modo revisión
		camera_screeen.modulate = Color(0.15, 0.15, 0.15)
		grid_overlay.set_review_mode(true)
		
	elif current_state == AppState.REVIEWING:
		captured_faces.append(current_scanned_colors.duplicate())
		current_state = AppState.SCANNING
		capture_button.text = "Capturar cara"
		
		camera_sprite.visible = true 
		camera_screeen.visible = false
		grid_overlay.set_review_mode(false)
		
		update_ui_text()

# Detecta los toques en la pantalla para cambiar el color manualmente
func _input(event: InputEvent) -> void:
	if captured_faces.size() >= 6 or current_state != AppState.REVIEWING:
		return
	
	var is_touch = (event is InputEventScreenTouch and event.is_pressed())
	var is_click = false
	
	if not is_android:
		is_click = (event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT)
	
	if is_click or is_touch:
		var touch_pos = event.position
		var ui_rects = grid_overlay.get_grid_rects()
		
		for i in range(ui_rects.size()):
			if ui_rects[i].has_point(touch_pos):
				var current_c = current_scanned_colors[i]
				var idx = color_cycle.find(current_c)
				if idx == -1: idx = 0
				
				var next_c = color_cycle[(idx + 1) % color_cycle.size()]
				current_scanned_colors[i] = next_c
				grid_overlay.update_detected_colors(current_scanned_colors)
				get_viewport().set_input_as_handled()
				break
