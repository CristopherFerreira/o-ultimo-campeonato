extends Area2D

# Item coletável: "vida" recupera uma vida, "bola" recupera munição (bolas para chutar)

@export_enum("bola", "vida") var tipo = "bola"
const BOLAS_POR_ITEM = 4

var tempo = randf() * TAU
var altura_inicial = null # guardada no primeiro quadro (funciona mesmo se a posição mudar ao criar)

func _ready() -> void:
	if (tipo == "vida"):
		$Sprite2D.texture = load("res://graficos/coracao.png")
		$Sprite2D.scale = Vector2(1.2, 1.2)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if (altura_inicial == null):
		altura_inicial = position.y
	tempo += delta
	position.y = altura_inicial + sin(tempo * 3.0) * 5.0
	if (tipo == "bola"):
		$Sprite2D.rotation += delta * 2.0

func _on_body_entered(body: Node2D) -> void:
	if (not body.is_in_group("jogador")):
		return
	
	if (tipo == "vida"):
		if (Jogo.vidas >= Jogo.VIDAS_MAXIMAS):
			return # vidas cheias: deixa o item para depois
		Jogo.vidas += 1
		Jogo.texto_flutuante(global_position + Vector2(0, -30), "+1 VIDA", Color(1, 0.4, 0.45))
		Jogo.poeira(global_position, Color(1, 0.4, 0.45), 14)
	else:
		if (Jogo.bolas >= Jogo.BOLAS_MAXIMAS):
			return
		Jogo.bolas = min(Jogo.bolas + BOLAS_POR_ITEM, Jogo.BOLAS_MAXIMAS)
		Jogo.texto_flutuante(global_position + Vector2(0, -30), "+%d BOLAS" % BOLAS_POR_ITEM, Color(1, 1, 1))
		Jogo.poeira(global_position, Color(1, 1, 1), 12)
	
	Jogo.tocar_som("figurinha")
	var fase = get_tree().current_scene
	if (fase.has_method("atualizar_hud")):
		fase.atualizar_hud()
	queue_free()
