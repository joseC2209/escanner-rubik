extends SceneTree

func _initialize() -> void:
	var solver := RubikSolver.new()
	solver.rotate_U()
	solver.rotate_R()
	solver.rotate_F()
	
	if not medir_caso("U R F", solver):
		quit(1)
		return
	
	# Se prepara el segundo caso desde el cubo resuelto
	solver.reset_to_solved()
	for i in range(2):
		solver.rotate_U()
		solver.rotate_R()
		solver.rotate_F()
		
	if not medir_caso("U R F U R F", solver):
		quit(1)
		return
	
	# Se prepara un caso de siete giros desde el cubo resuelto
	solver.reset_to_solved()
	for i in range(2):
		solver.rotate_U()
		solver.rotate_R()
		solver.rotate_F()
	solver.rotate_U()
	
	if not medir_caso("U R F U R F U", solver):
		quit(1)
		return
		
	# Se prepara un caso con giros simples, dobles e inversos
	solver.reset_to_solved()
	solver.rotate_F()
	
	for i in range(2):
		solver.rotate_R()
	
	for i in range(3):
		solver.rotate_U()
	
	for i in range(2):
		solver.rotate_F()
	
	solver.rotate_R()
	
	if not medir_caso("F R2 U' F2 R", solver):
		quit(1)
		return
		
	quit(0)
	
func medir_caso(nombre: String, solver: RubikSolver) -> bool:
	
	var solucion := solver.solve().strip_edges()
	if solucion.is_empty() or solucion.begins_with("Error:") or solucion == "Cubo ya resuelto":
		push_error("El caso %s no devolvió una secuencia: %s" % [nombre, solucion])
		return false
		
	var numero_movimientos := solucion.split(" ", false).size()
	
	var tiempos_us: Array[int] = []
	for i in range(21):
		var inicio_us := Time.get_ticks_usec()
		solver.solve()
		tiempos_us.append(Time.get_ticks_usec() - inicio_us)
		
	tiempos_us.sort()
	var mediana_us := tiempos_us[10]
	
	print("Caso %s | movimientos: %d | 21 ejecuciones | min: %d us | mediana: %d us | max: %d us" % [
		nombre, numero_movimientos, tiempos_us.front(), mediana_us, tiempos_us.back()
	])
	return true
