extends Control

const RUTA_MENU = "res://menu_principal.tscn"

@onready var mensaje: Label = $CenterContainer/VBoxContainer/Label
@onready var rueda: Control = $CenterContainer/VBoxContainer/RuedaCarga

func _ready() -> void:
	# Se carga el menú en segundo plano
	var error := ResourceLoader.load_threaded_request(RUTA_MENU, "PackedScene")
	if error != OK:
		mostrar_error()
		return
	
	# Se espera un fotograma entre consultas para que la rueda pueda seguir girando
	var estado := ResourceLoader.load_threaded_get_status(RUTA_MENU)
	while estado == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		estado = ResourceLoader.load_threaded_get_status(RUTA_MENU)
	
	if estado != ResourceLoader.THREAD_LOAD_LOADED:
		mostrar_error()
		return
		
	# Se cambia de escena cuando el menú ya está cargado
	var menu := ResourceLoader.load_threaded_get(RUTA_MENU) as PackedScene
	if menu == null or get_tree().change_scene_to_packed(menu) != OK:
		mostrar_error()
		
func mostrar_error() -> void:
	rueda.hide()
	mensaje.text = "No se pudo iniciar la aplicación."

func _process(delta: float) -> void:
	pass
