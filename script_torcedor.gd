extends "res://script_inimigo.gd"

# Torcedor rival: fica quase parado (em cima de plataformas ou no chão)
# e arremessa chinelos em arco na direção do jogador.

const CENA_CHINELO = preload("res://cena_chinelo.tscn")

var alcance_arremesso = 620
var tempo_recarga     = 1.0
var arremessando      = false
var alvo_arremesso    = Vector2.ZERO

func _ready() -> void:
	animacao_movimento = "parado"
	fator_velocidade   = 0.2 # anda bem pouquinho
	distancia_patrulha = 40
	pontos             = 150
	super()
	$AnimationPlayer.animation_finished.connect(_on_animacao_terminou)

func _physics_process(delta: float) -> void:
	if (morto):
		return
	
	tempo_recarga -= delta
	velocity.y += gravidade
	velocity.x = 0.0 if arremessando else velocidade * fator_velocidade * direcao
	move_and_slide()
	
	if (caiu_do_mapa()):
		return
	
	if (not arremessando):
		patrulhar()
		var jogador = procurar_jogador_torcedor()
		if (jogador != null and tempo_recarga <= 0):
			arremessando = true
			virar_para(jogador)
			alvo_arremesso = jogador.global_position
			$AnimationPlayer.play("arremessando")
	
	atualizar_sprite()
	verificar_contato()

# Enxerga o jogador mesmo um pouco abaixo (ele fica em cima das plataformas)
func procurar_jogador_torcedor() -> Node2D:
	var jogador = get_tree().get_first_node_in_group("jogador")
	if (jogador == null):
		return null
	var d = jogador.global_position - global_position
	if (abs(d.x) < alcance_arremesso and abs(d.y) < 320):
		return jogador
	return null

# Chamada pela animação, no quadro em que o braço vai para a frente
func soltar_chinelo() -> void:
	if (morto):
		return
	var chinelo = CENA_CHINELO.instantiate()
	var saida = global_position + Vector2(30 * direcao, -40)
	# Calcula a velocidade para o chinelo cair em cima de onde o jogador estava (tiro em arco)
	var t = 0.9
	var d = alvo_arremesso - saida
	chinelo.velocidade = Vector2(d.x / t, (d.y - 0.5 * chinelo.gravidade * t * t) / t)
	get_parent().get_parent().add_child(chinelo)
	chinelo.global_position = saida
	Jogo.tocar_som("arremesso")

func _on_animacao_terminou(nome) -> void:
	if (nome == "arremessando"):
		arremessando  = false
		tempo_recarga = 2.2
		$AnimationPlayer.play("parado")
