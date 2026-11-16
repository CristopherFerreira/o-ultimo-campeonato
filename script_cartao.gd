extends Area2D

# Cartão arremessado pelo árbitro: voa reto e tira uma vida do jogador

var direcao       = 1
var amarelo       = false # o árbitro arremessa cartões vermelhos e amarelos
var velocidade    = 450
var tempo_de_vida = 2.5

func _ready() -> void:
	if (amarelo):
		$Sprite2D.texture = load("res://graficos/cartao_amarelo_pixel.png")
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(tempo_de_vida).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position.x += velocidade * direcao * delta
	$Sprite2D.rotation += 12 * direcao * delta

func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("jogador")):
		body.levar_dano()
	Jogo.poeira(global_position, Color(1, 0.85, 0.2, 0.9) if amarelo else Color(1, 0.3, 0.3, 0.9), 8)
	queue_free() # some ao acertar o jogador ou bater no cenário
