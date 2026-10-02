extends Node

@export var flicker_labels: Array[NodePath] = []
@export var glow_color: Color = Color(0.7, 0.6, 1.0, 1.0) # #B399FF
@export var pulse_speed: float = 1.5
@export var flicker_chance: float = 0.02 # peluang kedip tiap frame

var labels: Array[Label] = []

func _ready() -> void:
	for path in flicker_labels:
		var lbl = get_node(path) as Label
		if lbl:
			labels.append(lbl)
		else:
			print("Gagal load label di path: ", path)
	print("Total labels ke-load: ", labels.size())
	_pulse_loop()

func _pulse_loop() -> void:
	while true:
		for lbl in labels:
			var t = create_tween()
			t.tween_property(lbl, "modulate:a", 0.75, pulse_speed).set_trans(Tween.TRANS_SINE)
			t.tween_property(lbl, "modulate:a", 1.0, pulse_speed).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(pulse_speed * 2).timeout

func _process(_delta: float) -> void:
	# efek kedip acak, kesan "echo/glitch" tipis
	if randf() < flicker_chance:
		for lbl in labels:
			lbl.modulate.a = randf_range(0.4, 0.7)
			await get_tree().create_timer(0.05).timeout
			lbl.modulate.a = 1.0
