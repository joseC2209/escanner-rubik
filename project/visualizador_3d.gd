extends Node3D

@onready var pivot = $Pivot
@onready var piezas_container = $Piezas

# Variable para bloquear animaciones simultáneas
var is_animating = false

# Diccionario que define el eje de rotación de cada uno de los movimientos (U, R, F)
var ejes_rotacion = {
	"U" : Vector3.UP,     # Eje Y
	"R" : Vector3.RIGHT,  # Eje X
	"F" : Vector3.FORWARD # Eje Z
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Prueba: girar R 90 grados al arrancar
	rotate_face("R", -1) # -1 = 90º (horario), 1 = -90º (antihorario), -2 = 180º
	pass # Replace with function body.

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
	# Transición suave (EASE_IN_OUT) con curva SINE para que quede natural y velocidad 1.0
	tween.tween_property(pivot, "transform:basis", pivot.transform.basis.rotated(eje, angulo_rad), 1.75)\
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
	pivot.transform.basis = Basis()
	
	is_animating = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
