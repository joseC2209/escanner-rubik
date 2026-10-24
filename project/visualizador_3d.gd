extends Node3D

@onready var pivot = $Pivot
@onready var piezas_container = $Piezas

# Variable para bloquear animaciones simultáneas
var is_animating = false

# -1 = 90º (horario), 1 = -90º (antihorario), -2 = 180º
# Diccionario que define el eje de rotación de cada uno de los movimientos (U, R, F)
var ejes_rotacion = {
	"U" : Vector3.UP,     # Eje Y
	"R" : Vector3.RIGHT,  # Eje X
	"F" : Vector3.FORWARD # Eje Z
}

# Controles de la interfaz
@onready var btn_anterior = $CanvasLayer/MarginContainer/HBoxContainer/CenterContainer/BtnAnterior
@onready var btn_siguiente = $CanvasLayer/MarginContainer/HBoxContainer/CenterContainer2/BtnSiguiente
@onready var move_label = $CanvasLayer/MarginContainer2/MoveLabel

# Cola de movimientos
var secuencia_movimientos = []
var paso_actual = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Global.colores_cubo.size() == 6:
		generar_colores_escaneados(Global.colores_cubo)
	else:
		# Fallback para abrir esta escena directamente durante las pruebas.
		generar_colores_resueltos()
	
	# Se carga la solución real que el escáner ha dejado guardada en el Global
	if Global.solucion_actual != "":
		cargar_solucion(Global.solucion_actual)
	else:
		# Caso de prueba
		cargar_solucion("U F2 R' U'")

func rotate_face(face_name: String, turns: int):
	if is_animating:
		return
		
	is_animating = true
	
	# Se identifican qué piezas deben girar según las coordenadas actuales
	var piezas_a_girar = []
	for cubie in piezas_container.get_children():
		var pos = cubie.global_position
		
		# Se seleccionan las piezas por su posición espacial
		var threshold = 0.1 # Margen de error por los decimales de la física
		if face_name == "U" and pos.y > threshold:
			piezas_a_girar.append(cubie)
		elif face_name == "R" and pos.x > threshold:
			piezas_a_girar.append(cubie)
		elif face_name == "F" and pos.z > threshold:
			piezas_a_girar.append(cubie)
			
	# Se emparentan las piezas seleccionadas al pivote central
	for cubie in piezas_a_girar:
		var transform_global = cubie.global_transform
		piezas_container.remove_child(cubie)
		pivot.add_child(cubie)
		cubie.global_transform = transform_global # Mantiene su posición real
		
	# Se anima la rotación del pivote
	var angulo_rad = turns * (PI / 2.0) # 90 grados en radianes
	var eje = ejes_rotacion[face_name]
	
	var tween = get_tree().create_tween()
	# Transición suave (EASE_IN_OUT) con curva SINE para que quede natural y velocidad 2.75
	tween.tween_property(pivot, "rotation", eje * angulo_rad, 2.75)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	tween.finished.connect(_on_rotation_finished.bind(piezas_a_girar))
	
# Se ejecuta al terminar la animación
func _on_rotation_finished(piezas_giradas: Array):
	# Se devuelven las piezas al contenedor principal con su nueva posición
	for cubie in piezas_giradas:
		var transform_global = cubie.global_transform
		pivot.remove_child(cubie)
		piezas_container.add_child(cubie)
		cubie.global_transform = transform_global
		
	# Se resetea el pivote a 0,0,0
	pivot.rotation = Vector3.ZERO
	
	is_animating = false

# El intérprete debe traducir el string "U F2 R'" a una lista de diccionarios
func cargar_solucion(solucion_str: String):
	secuencia_movimientos.clear()
	paso_actual = 0
	if solucion_str == "Cubo ya resuelto":
		actualizar_ui()
		return
	
	# Se trocea el string tomando como separador los espacios
	var movimientos_raw = solucion_str.strip_edges().split(" ")
	
	for m in movimientos_raw:
		if m == "": continue
		
		var face = m[0] # La primera letra siempre es la cara (U, F, R)
		var turns = -1  # Por defecto lo ponemos en giro horario
		
		# Si el movimiento tiene modificaciones (' o 2)
		if m.length() > 1:
			if m[1] == "'":
				turns = 1  # Antihorario
			elif m[1] == "2":
				turns = -2 # 180 grados
				
		secuencia_movimientos.append({"face": face, "turns": turns, "texto": m})
		
	actualizar_ui()
	
func actualizar_ui():
	# Si no hay movimientos o el cubo está ya resuelto
	if secuencia_movimientos.is_empty():
		move_label.text = "[center]Cubo resuelto[/center]"
		btn_anterior.disabled = true
		btn_siguiente.disabled = true
		return
		
	# Se construye la línea de movimientos con formato BBCode
	var texto_completo = "[center]"
	
	for i in range(secuencia_movimientos.size()):
		var mov = secuencia_movimientos[i]["texto"]
		if i == paso_actual:
			# Se resalta en verde y negrita el movimiento actual
			texto_completo += "[color=dark_green][b]" + mov + "[/b][/color] "
		else:
			# Texto normal para los movimientos ya hechos o los futuros
			texto_completo += mov + " "
	
	# Se añade estado de completado si ya no quedan pasos por hacer
	if paso_actual >= secuencia_movimientos.size():
		texto_completo += "\n[color=yellow]¡Cubo completado![/color]"
	else:
		texto_completo += "\n(" + str(paso_actual) + "/" + str(secuencia_movimientos.size()) + ")"
	
	texto_completo += "[/center]"
	
	move_label.text = texto_completo
	
	# Habilitar/Deshabilitar botones según los límites
	btn_anterior.disabled = (paso_actual == 0)
	btn_siguiente.disabled = (paso_actual >= secuencia_movimientos.size())
	
# Al pulsar el botón "Siguiente"
func _on_btn_siguiente_pressed():
	if is_animating or paso_actual >= secuencia_movimientos.size(): return
	
	var move = secuencia_movimientos[paso_actual]
	rotate_face(move["face"], move["turns"])
	paso_actual += 1
	actualizar_ui()
	
# Al pulsar el botón "Anterior"
func _on_btn_anterior_pressed():
	if is_animating or paso_actual <= 0: return
	
	paso_actual -= 1
	var move = secuencia_movimientos[paso_actual]
	# Para deshacer el movimiento, se le tiene que dar la vuelta al signo de los giros
	rotate_face(move["face"], -move["turns"])
	actualizar_ui()

# Pinta el cubo con los colores capturados, respetando el orden de las caras:
# U, F, R, B, L, D; cada cara contiene TL, TR, BL y BR.
func generar_colores_escaneados(faces: Array):
	var mat_negro = StandardMaterial3D.new()
	mat_negro.albedo_color = Color(0.1, 0.1, 0.1)

	for cubie in piezas_container.get_children():
		cubie.material_override = mat_negro
		var pos = cubie.position

		# Cada condición asigna la posición de la pegatina dentro de su cara.
		if pos.y > 0: anadir_pegatina(cubie, Vector3(0, 0.476, 0), Vector3(-90, 0, 0), color_de_codigo(color_de_cara(faces, 0, indice_superior(pos))))
		if pos.y < 0: anadir_pegatina(cubie, Vector3(0, -0.476, 0), Vector3(90, 0, 0), color_de_codigo(color_de_cara(faces, 5, indice_inferior(pos))))
		if pos.x > 0: anadir_pegatina(cubie, Vector3(0.476, 0, 0), Vector3(0, 90, 0), color_de_codigo(color_de_cara(faces, 2, indice_derecha(pos))))
		if pos.x < 0: anadir_pegatina(cubie, Vector3(-0.476, 0, 0), Vector3(0, -90, 0), color_de_codigo(color_de_cara(faces, 4, indice_izquierda(pos))))
		if pos.z > 0: anadir_pegatina(cubie, Vector3(0, 0, 0.476), Vector3(0, 0, 0), color_de_codigo(color_de_cara(faces, 1, indice_frontal(pos))))
		if pos.z < 0: anadir_pegatina(cubie, Vector3(0, 0, -0.476), Vector3(0, 180, 0), color_de_codigo(color_de_cara(faces, 3, indice_trasera(pos))))

func color_de_cara(faces: Array, cara: int, indice: int) -> String:
	return str(faces[cara][indice])

func color_de_codigo(codigo: String) -> Color:
	match codigo:
		"W": return Color.WHITE
		"Y": return Color.YELLOW
		"R": return Color.RED
		"O": return Color.DARK_ORANGE
		"G": return Color.GREEN
		"B": return Color.BLUE
		_: return Color.MAGENTA

func indice_superior(pos: Vector3) -> int:
	if pos.z < 0 and pos.x < 0: return 0
	if pos.z < 0: return 1
	if pos.x < 0: return 2
	return 3

func indice_inferior(pos: Vector3) -> int:
	if pos.z > 0 and pos.x < 0: return 0
	if pos.z > 0: return 1
	if pos.x < 0: return 2
	return 3

func indice_frontal(pos: Vector3) -> int:
	if pos.y > 0 and pos.x < 0: return 0
	if pos.y > 0: return 1
	if pos.x < 0: return 2
	return 3

func indice_derecha(pos: Vector3) -> int:
	if pos.z > 0 and pos.y > 0: return 0
	if pos.z < 0 and pos.y > 0: return 1
	if pos.z > 0: return 2
	return 3

func indice_trasera(pos: Vector3) -> int:
	if pos.x > 0 and pos.y > 0: return 0
	if pos.x < 0 and pos.y > 0: return 1
	if pos.x > 0: return 2
	return 3

func indice_izquierda(pos: Vector3) -> int:
	if pos.z < 0 and pos.y > 0: return 0
	if pos.z > 0 and pos.y > 0: return 1
	if pos.z < 0: return 2
	return 3

# Se generan pegatinas resueltas si se abre esta escena sin pasar por el escaneo.
func generar_colores_resueltos():
	# Material para el plásico del cubo (gris muy oscuro, casi negro)
	var mat_negro = StandardMaterial3D.new()
	mat_negro.albedo_color = Color(0.1, 0.1, 0.1)
	
	for cubie in piezas_container.get_children():
		cubie.material_override = mat_negro
		var pos = cubie.position
		
		# Dependiendo de la posición tridimensional, se le pegan los colores
		# Cara superior (Blanco)
		if pos.y > 0: anadir_pegatina(cubie, Vector3(0, 0.476, 0), Vector3(-90, 0, 0), Color.WHITE)
		# Cara inferior (Amarillo)
		if pos.y < 0: anadir_pegatina(cubie, Vector3(0, -0.476, 0), Vector3(90, 0, 0), Color.YELLOW)
		# Cara derecha (Rojo)
		if pos.x > 0: anadir_pegatina(cubie, Vector3(0.476, 0, 0), Vector3(0, 90, 0), Color.RED)
		# Cara izquieda (Naranja)
		if pos.x < 0: anadir_pegatina(cubie, Vector3(-0.476, 0, 0), Vector3(0, -90, 0), Color.DARK_ORANGE)
		# Cara frontal (Verde)
		if pos.z > 0: anadir_pegatina(cubie, Vector3(0, 0, 0.476), Vector3(0, 0, 0), Color.GREEN)
		# Cara trasera (Azul)
		if pos.z < 0: anadir_pegatina(cubie, Vector3(0, 0, -0.476), Vector3(0, 180, 0), Color.BLUE)
		
# Instancia un QuadMesh para simular la pegatina
func anadir_pegatina(padre: Node3D, pos_relativa: Vector3, rotacion_grados: Vector3, color: Color):
	var pegatina = MeshInstance3D.new()
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.85, 0.85) # Más pequeña que la pieza (0.95) para dejar el borde negro
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	# Se hace que el color sea puro y no se vea alterado demasiado por las sombras
	mat.roughness = 0.3
	mesh.material = mat
	
	pegatina.mesh = mesh
	padre.add_child(pegatina)
	pegatina.position = pos_relativa
	pegatina.rotation_degrees = rotacion_grados

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
