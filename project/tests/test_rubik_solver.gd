extends SceneTree

func _initialize() -> void:
	var solver := RubikSolver.new()
	var esperado := "[ P0O0 P1O0 P2O0 P3O0 P4O0 P5O0 P6O0 P7O0 ]"
	var obtenido := solver.get_state_string()
	
	if obtenido != esperado:
		push_error("Estado inicial incorrecto. Esperado: %s. Obtenido: %s" % [esperado,obtenido])
		quit(1)
		return
		
	print("Ok: el cubo comienza resuelto")

	var estado_inicial := obtenido
	
	var giros := {"U": solver.rotate_U, "R": solver.rotate_R, "F": solver.rotate_F}
	
	for cara in giros:
		var girar: Callable = giros[cara]
		girar.call()
		
		if solver.get_state_string() == estado_inicial:
			push_error("Un giro %s debería cambiar el estado del cubo" % cara)
			quit(1)
			return
			
		for i in range(3):
			girar.call()
			
		if solver.get_state_string() != estado_inicial:
			push_error("Cuatro giros %s deberían recuperar el estado inicial" % cara)
			quit(1)
			return
		
		print("OK: un giro %s cambia el estado y cuatro lo restauran" % cara)
	
	solver.rotate_U()
	var esperado_tras_u := "[ P2O0 P0O0 P3O0 P1O0 P4O0 P5O0 P6O0 P7O0 ]"
	var obtenido_tras_u := solver.get_state_string()
	
	if obtenido_tras_u != esperado_tras_u:
		push_error("Giro U incorrecto. Esperado: %s. Obtenido: %s" % [esperado_tras_u, obtenido_tras_u])
		quit(1)
		return
		
	print("OK: U desplaza las esquinas superiores en sentido horario")
	
	solver.reset_to_solved()
	var estado_reiniciado := solver.get_state_string()
	
	if estado_reiniciado != estado_inicial:
		push_error("El reinicio no restauró el cubo. Estado obtenido: %s" % estado_reiniciado)
		quit(1)
		return
		
	print("OK: el reinicio restaura el cubo resuelto")
	
	for cara in giros:
		solver.reset_to_solved()
		var girar: Callable = giros[cara]
		girar.call()
		
		var solucion_esperada := "%s'" % cara
		var solucion := solver.solve().strip_edges()
		
		if solucion != solucion_esperada:
			push_error("Tras %s se esperaba %s. Solución obtenida: %s" % [cara, solucion_esperada, solucion])
			quit(1)
			return
			
		print("OK: el solucionador devuelve %s tras un giro %s" % [solucion, cara])
	
		solver.reset_to_solved()
		girar.call()
		girar.call()
		
		var medio_giro_esperado := "%s2" % cara
		var solucion_medio_giro := solver.solve().strip_edges()
		
		if solucion_medio_giro != medio_giro_esperado:
			push_error("Se esperaba %s. Solución obtenida: %s" % [medio_giro_esperado, solucion_medio_giro])
			quit(1)
			return
			
		print("OK: el solucionador devuelve %s tras dar un medio giro" % solucion_medio_giro)
	
	solver.reset_to_solved()
	solver.rotate_U()
	solver.rotate_R()
	
	var estado_antes_de_resolver := solver.get_state_string()
	var solucion_dos_giros := solver.solve().strip_edges()
	
	if solver.get_state_string() != estado_antes_de_resolver:
		push_error("solve() modificó el estado del cubo")
		quit(1)
		return
	
	print("OK: solve() conserva el estado de entrada")
	
	var movimientos := solucion_dos_giros.split(" ", false)
	
	if movimientos.size() != 2:
		push_error("Tras U R se esperaban dos movimientos. Solución obtenida: %s" % [solucion_dos_giros])
		quit(1)
		return
		
	print("OK: la solución de U R contiende dos movimientos: %s" % solucion_dos_giros)
	
	var cuartos_por_sufijo := {"": 1, "2": 2, "'": 3}
	
	for movimiento in movimientos:
		var cara := movimiento.left(1)
		var sufijo := movimiento.substr(1)
		
		if not giros.has(cara) or not cuartos_por_sufijo.has(sufijo):
			push_error("Movimiento desconocido: %s" % movimiento)
			quit(1)
			return
			
		var girar: Callable = giros[cara]
		var cuartos: int = cuartos_por_sufijo[sufijo]
		for i in range(cuartos):
			girar.call()
			
	if solver.get_state_string() != estado_inicial:
		push_error("La secuencia %s no restaura el cubo" % solucion_dos_giros)
		quit(1)
		return
	
	print("OK: aplicar la secuencia devuelta restaura el cubo")
	
	var respuesta_cubo_resuelto := solver.solve()
	
	if respuesta_cubo_resuelto != solver.solve():
		push_error("Se esperaba 'Cubo ya resuelto'. Respuesta obtenida: %s" % [respuesta_cubo_resuelto])
		quit(1)
		return
		
	print ("OK: solve() reconoce un cubo ya resuelto")
	
	# Se parte de un cubo girado para comprobar que la carga sustituye su estado
	solver.rotate_U()
	
	var caras_resueltas := [
		["W", "W", "W", "W"], # U: blanca
		["G", "G", "G", "G"], # F: verde
		["R", "R", "R", "R"], # R: roja
		["B", "B", "B", "B"], # B: azul
		["O", "O", "O", "O"], # L: naranja
		["Y", "Y", "Y", "Y"], # D: amarilla
	]
	solver.load_from_colors(caras_resueltas)
	
	var estado_cargado := solver.get_state_string()
	if estado_cargado != estado_inicial:
		push_error("Las seis caras no reconstruyen el cubo resuelto: %s" % estado_cargado)
		quit(1)
		return
		
	print("OK: las seis caras reconstruyen el cubo resuelto")
	
	# Se representan las pegatinas que se verían tras un giro U
	var caras_tras_u := [
		["W", "W", "W", "W"], # U
		["R", "R", "G", "G"], # F
		["B", "B", "R", "R"], # R
		["O", "O", "B", "B"], # B
		["G", "G", "O", "O"], # L
		["Y", "Y", "Y", "Y"], # D
	]
	solver.load_from_colors(caras_tras_u)
	
	var estado_cargado_tras_u := solver.get_state_string()
	if estado_cargado_tras_u != esperado_tras_u:
		push_error("Las caras del cubo girado no reproducen U: %s" % estado_cargado_tras_u)
		quit(1)
		return
		
	print("OK: las seis caras reconstruyen el cubo tras un giro U")
	
	# Si simula un escaneo incompleto quitando la última cara
	var caras_incompletas := caras_resueltas.duplicate()
	caras_incompletas.pop_back()
	solver.load_from_colors(caras_incompletas)
	
	var estado_tras_cara_incompleta := solver.get_state_string()
	if estado_tras_cara_incompleta != esperado_tras_u:
		push_error("La carga de cinco caras modificó el cubo: %s" % [estado_tras_cara_incompleta])
		quit(1)
		return
		
	print("OK: una carga de cinco caras conserva el estado anterior")
	
	var caras_con_hueco := caras_resueltas.duplicate()
	caras_con_hueco[0] = ["W", "W", "W"]
	solver.load_from_colors(caras_con_hueco)
	
	if solver.get_state_string() != esperado_tras_u:
		push_error("Una cara con tres pegatinas modificó el cubo")
		quit(1)
		return
		
	print("OK: una cara con tres pegatinas conserva el estado anterior")
	
	var caras_con_color_desconocido := caras_resueltas.duplicate()
	caras_con_color_desconocido[0] = ["X", "W", "W", "W"]
	solver.load_from_colors(caras_con_color_desconocido)
	
	if solver.get_state_string() != esperado_tras_u:
		push_error("Un color desconocido modificó el cubo")
		quit(1)
		return
		
	print("OK: un color desconocido conserva el estado anterior")
	
	# Se giran las tres pegatinas de la esquina superior frontal derecha
	var caras_con_esquina_girada := caras_resueltas.duplicate(true)
	caras_con_esquina_girada[0][3] = "R"
	caras_con_esquina_girada[1][1] = "W"
	caras_con_esquina_girada[2][0] = "G"
	solver.load_from_colors(caras_con_esquina_girada)
	
	var respuesta_irresoluble := solver.solve()
	if not respuesta_irresoluble.begins_with("Error: Cubo irresoluble."):
		push_error("Se esperaba un cubo irresoluble. Respuesta: %s" % respuesta_irresoluble)
		quit(1)
		return
		
	print("OK: una sola esquina girada hace que el cubo sea irresoluble")
	
	# La esquina blanca, verde y roja pasa a tener los colores de otra pieza
	var caras_con_pieza_repetida := caras_resueltas.duplicate(true)
	caras_con_pieza_repetida[1][1] = "O"
	caras_con_pieza_repetida[2][0] = "G"
	solver.load_from_colors(caras_con_pieza_repetida)
	
	var respuesta_pieza_repetida := solver.solve()
	if not respuesta_pieza_repetida.begins_with("Error: Cubo irresoluble."):
		push_error("Se esperaba un error por pieza repetida. Respuesta: %s" % respuesta_pieza_repetida)
		quit(1)
		return
		
	print("OK: el solucionador rechaza una pieza repetida")
	
	# Se susituye el azul de la esquina 0 por otro blanco
	var caras_con_pieza_desconocida := caras_resueltas.duplicate(true)
	caras_con_pieza_desconocida[3][1] = "W"
	solver.load_from_colors(caras_con_pieza_desconocida)
	
	var respuesta_pieza_desconocida := solver.solve()
	if not respuesta_pieza_desconocida.begins_with("Error: Cubo irresoluble."):
		push_error("Se esperaba un error por pieza desconocida. Respuesta: %s" % [respuesta_pieza_desconocida])
		quit(1)
		return
		
	print("OK: el solucionador rechaza una pieza desconocida")
	
	# Se intercambian las dos pegatinas laterales de una esquina
	var caras_con_esquina_invertida := caras_resueltas.duplicate(true)
	caras_con_esquina_invertida[1][1] = "R"
	caras_con_esquina_invertida[2][0] = "G"
	solver.load_from_colors(caras_con_esquina_invertida)
	
	var respuesta_esquina_invertida := solver.solve()
	if not respuesta_esquina_invertida.begins_with("Error: Cubo irresoluble."):
		push_error("Se esperaba rechazar la esquina invertida. Respuesta: %s" % [respuesta_esquina_invertida])
		quit(1)
		return
		
	print("OK: el solucionador rechaza una esquina con los colores invertidos")
	
	# Se cargan las pegatinas de un cubo resuelto tras un giro R
	var caras_tras_r := [
		["W", "G", "W", "G"], # U
		["G", "Y", "G", "Y"], # F
		["R", "R", "R", "R"], # R
		["W", "B", "W", "B"], # B
		["O", "O", "O", "O"], # L
		["Y", "B", "Y", "B"], # D
	]
	solver.load_from_colors(caras_tras_r)
	
	var esperado_tras_r := "[ P0O0 P3O2 P2O0 P7O1 P4O0 P1O1 P6O0 P5O2 ]"
	var obtenido_tras_r := solver.get_state_string()
	if obtenido_tras_r != esperado_tras_r:
		push_error("Las caras del cubo girado no reproducen R: %s" % obtenido_tras_r)
		quit(1)
		return
		
	print("OK: las seis caras reconstruyen el cubo tras un giro R")
	
	var solucion_tras_cargar_r := solver.solve().strip_edges()
	if solucion_tras_cargar_r != "R'":
		push_error("Tras cargar las caras de R se esperaba R'. Respuesta: %s" % [solucion_tras_cargar_r])
		quit(1)
		return
		
	print("OK: las caras del cubo girado con R se resuelven con R'")
	
	# Se comprueba si algún movimiento individual alcanza el estado de U R
	for cara in giros:
		solver.reset_to_solved()
		var girar: Callable = giros[cara]
		
		for cuartos in range(1, 4):
			girar.call()
			
			if solver.get_state_string() == estado_antes_de_resolver:
				push_error("U R también se alcanza con %s en %d cuartos de vuelta" % [cara, cuartos])
				quit(1)
				return
			
	print("OK: U R no se alcanza con un solo movimiento")
	
	quit(0)
