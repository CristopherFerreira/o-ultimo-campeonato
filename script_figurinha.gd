extends Area2D

# Figurinha da Copa: item para coletar (desafio de algumas fases)

var tempo = randf() * TAU
var altura_inicial = 0.0

func _ready() -> void:
	add_to_group("figurinhas")
	altura_inicial = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Flutua e gira devagar para chamar atenção
	tempo += delta
	position.y = altura_inicial + sin(tempo * 3.0) * 6.0
	$Sprite2D.scale.x = cos(tempo * 2.0)

func _on_body_entered(body: Node2D) -> void:
	if (not body.is_in_group("jogador")):
		return
	Jogo.tocar_som("figurinha")
	Jogo.poeira(global_position, Color(1, 0.85, 0.2), 14)
	Jogo.texto_flutuante(global_position + Vector2(0, -40), "+50")
	var fase = get_tree().current_scene
	if (fase.has_method("coletar_figurinha")):
		fase.coletar_figurinha()
	queue_free()
