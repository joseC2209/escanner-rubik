extends Control

var angulo := 0.0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	# Se actualiza el ángulo según el tiempo transcurrido y se limita a una vuelta
	angulo = fposmod(angulo + TAU * delta, TAU)
	# Se vuelve a dibujar para mostrar el arco en la posición original
	queue_redraw()
	
func _draw() -> void:
	# Se centra en el nodo
	var centro := size / 2.0
	# Se usa el lado más corto con margen para que el trazo no se recorte
	var radio := minf(size.x, size.y) / 2.0 - 4.0

	# Anillo de fondo
	draw_arc(centro, radio, 0.0, TAU, 48, Color("3D5274"), 4.0, true)
	# Color claro que da una vuelta por segundo
	draw_arc(centro, radio, angulo, angulo + TAU / 3.0, 24, Color("F2F6FF"), 4.0, true)
