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
	
	# Comprueba que la clase C++ está disponible en Godot.
	scanner.test_connection()
	
	# Encendido de la cámara a través de OpenCV
	scanner.open_camera()
	# Se usa un Sprite2D para mostrar el frame sin depender del tamaño mínimo del TextureRect.
	camera_sprite = Sprite2D.new()
	camera_sprite.position = get_viewport_rect().size / 2.0
	camera_sprite.z_index = 10
	add_child(camera_sprite)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if scanner:
		# Se pide a C++ el fotograma actual de la webcam
		var img = scanner.get_frame()
		
		# Cada frame válido se convierte en una textura que Godot puede dibujar.
		if img != null and not img.is_empty():
			# RGBA8 evita problemas de compatibilidad al subir texturas RGB8 a Vulkan.
			img.convert(Image.FORMAT_RGBA8)
			# Se fuerza el dibujo por encima de otros nodos y con color neutro.
			camera_screeen.visible = true
			camera_screeen.modulate = Color.WHITE
			camera_screeen.z_index = 10
			var texture = ImageTexture.create_from_image(img)
			camera_sprite.texture = texture
			# Se escala la imagen para cubrir todo el viewport del juego.
			camera_sprite.scale = Vector2(get_viewport_rect().size.x / float(img.get_width()), get_viewport_rect().size.y / float(img.get_height()))
