extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var scanner = ScannerCore.new()
	add_child(scanner)
	scanner.test_connection()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
