extends Area2D

# Chegada da fase. Pode ser um "gol" (fases normais) ou o "portao" do estádio (final).
# Fica trancado com um cadeado até o desafio da fase ser cumprido.

@export_enum("gol", "portao") var tipo = "gol"

func _ready() -> void:
	var e_portao = (tipo == "portao")
	$Visual.visible = not e_portao
	$Fachada.visible = e_portao
	$Grade.visible = e_portao
	if (e_portao):
		$Cadeado.position = Vector2(60, -20)

func fechar() -> void:
	$Cadeado.visible = true
	$Cadeado.modulate.a = 1.0
	# Cadeado balançando de leve
	var tween = create_tween().set_loops()
	tween.tween_property($Cadeado, "rotation", 0.12, 0.6)
	tween.tween_property($Cadeado, "rotation", -0.12, 0.6)

func abrir() -> void:
	if (not $Cadeado.visible):
		return
	Jogo.poeira($Cadeado.global_position, Color(1, 0.85, 0.2), 30)
	var tween = create_tween().set_parallel(true)
	tween.tween_property($Cadeado, "position:y", $Cadeado.position.y - 80, 0.6)
	tween.tween_property($Cadeado, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(func(): $Cadeado.visible = false)
	# O portão do estádio sobe a grade
	if (tipo == "portao"):
		create_tween().tween_property($Grade, "position:y", $Grade.position.y - 160, 1.5).set_trans(Tween.TRANS_SINE)
