extends SceneTree

func _initialize() -> void:
	var scanner := ScannerCore.new()
	
	# Se crea una imagen blanca de nueve píxeles
	var imagen := Image.create(3, 3, false, Image.FORMAT_RGB8)
	imagen.fill(Color.WHITE)
	var regiones := [Rect2(0, 0, 3, 3)]
	
	var muestras := scanner.sample_colors_from_image(imagen, regiones)
	
	if muestras.size() != 1 or not muestras[0].is_equal_approx(Color.WHITE):
		push_error("La mediana de una región blanca debe ser blanca")
		scanner.free()
		quit(1)
		return
	
	print("OK: una región uniforme conserva su color")
	
	# Se simula una marca negra que ocupa uno de los nueve píxeles
	imagen.set_pixel(1, 1, Color.BLACK)
	muestras = scanner.sample_colors_from_image(imagen, regiones)
	
	if muestras.size() != 1 or not muestras[0].is_equal_approx(Color.WHITE):
		push_error("Una mancha de un píxel no debería alterar la mediana blanca")
		scanner.free()
		quit(1)
		return
		
	print("OK: una mancha pequeña no altera la mediana")
	
	# Con dos píxeles, la mediana promedia sus valores
	var imagen_par := Image.create(2, 1, false, Image.FORMAT_RGB8)
	imagen_par.set_pixel(0, 0, Color.BLACK)
	imagen_par.set_pixel(1, 0, Color.WHITE)
	
	var muestras_par := scanner.sample_colors_from_image(imagen_par, [Rect2(0, 0, 2, 1)])
	var esperado_par := Color(127.0 / 255.0, 127.0 / 255.0, 127.0 / 255.0)
	
	if muestras_par.size() != 1 or not muestras_par[0].is_equal_approx(esperado_par):
		push_error("La mediana de negro y blanco debería ser gris de valor 127")
		scanner.free()
		quit(1)
		return
		
	print("OK: una cantidad par promedia los dos valores centrales")
	
	# Se crean dos regiones contiguas con colores diferentes
	var imagen_regiones := Image.create(4, 2, false, Image.FORMAT_RGB8)
	imagen_regiones.fill(Color.RED)
	imagen_regiones.fill_rect(Rect2i(2, 0, 2, 2), Color.BLUE)
	
	var muestras_regiones := scanner.sample_colors_from_image(imagen_regiones, [Rect2(0, 0, 2, 2), Rect2(2, 0, 2, 2)])
	
	if muestras_regiones.size() != 2:
		push_error("Se esperaban dos muestras, una por región")
		scanner.free()
		quit(1)
		return
		
	if not muestras_regiones[0].is_equal_approx(Color.RED) or not muestras_regiones[1].is_equal_approx(Color.BLUE):
		push_error("Las muestras no conservan el orden de las regiones o los canales RGB")
		scanner.free()
		quit(1)
		return
		
	print("OK: las muestras conservan las regiones y el orden RGB")
	
	# Se comprueba que la conversión interna a RGB no modifica la imagen original
	var imagen_rgba := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	imagen_rgba.fill(Color(1.0, 0.0, 0.0, 0.5))
	var datos_originales := imagen_rgba.get_data()
	
	var muestras_rgba := scanner.sample_colors_from_image(imagen_rgba, [Rect2(0, 0, 2, 2)])
	
	if muestras_rgba.size() != 1 or not muestras_rgba[0].is_equal_approx(Color.RED):
		push_error("La imagen RGBA debería producir una muestra roja")
		scanner.free()
		quit(1)
		return
		
	if imagen_rgba.get_format() != Image.FORMAT_RGBA8 or imagen_rgba.get_data() != datos_originales:
		push_error("La extracción modificó la imagen original")
		scanner.free()
		quit(1)
		return
		
	print("OK: la extracción conserva el formato y los píxeles originales")
	
	scanner.free()
	quit(0)
