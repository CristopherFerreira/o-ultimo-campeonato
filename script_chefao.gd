extends "res://script_inimigo.gd"

# Chefão "Cartão Vermelho": persegue o jogador e dá marretadas de cima para baixo.
# Precisa levar vários golpes (bola ou carrinho) para ser derrotado.
# Com metade da vida entra em FÚRIA: fica mais rápido e a marretada solta
# ondas de choque pelo chão, que o jogador precisa pular.

const CENA_ONDA = preload("res://cena_onda.tscn")

var vida_maxima          = 12
var vida                 = 12
var alcance_visao        = 750
var alcance_marretada    = 170
var tempo_recarga        = 1.0
var tempo_invulneravel   = 0.0
var atacando             = false
var ja_viu_jogador       = false
var em_furia             = false
var recarga_marretada    = 1.2

func _ready() -> void:
	animacao_movimento       = "parado"
	fator_velocidade         = 0.45
	pontos                   = 3000
	distancia_sensor         = 60
	sprite_olha_para_direita = true  # o desenho em pixel art está virado para a direita
	super()
	add_to_group("chefao")
	$AnimationPlayer.animation_finished.connect(_on_animacao_terminou)
	vida = vida_maxima
	$BarraVida.max_value = vida_maxima
	$BarraVida.value     = vida

func _physics_process(delta: float) -> void:
	if (morto):
		return

	tempo_recarga      -= delta
	tempo_invulneravel -= delta
	velocity.y += gravidade

	var jogador = procurar_jogador(alcance_visao)

	# Primeira vez que encontra o jogador: anuncia a luta
	if (jogador != null and not ja_viu_jogador):
		ja_viu_jogador = true
		avisar_fase("anunciar", "CUIDADO!\nCARTÃO VERMELHO!")
		Jogo.tocar_som("apito")

	if (atacando):
		velocity.x = 0
	elif (jogador != null):
		# Persegue o jogador (sem se jogar no buraco)
		if (abs(jogador.global_position.x - global_position.x) > 20):
			virar_para(jogador)

		if (abs(jogador.global_position.x - global_position.x) < alcance_marretada and tempo_recarga <= 0):
			marretada()
			velocity.x = 0
		elif (tem_chao_a_frente()):
			velocity.x = velocidade * fator_velocidade * direcao
			$AnimationPlayer.play("andando")
		else:
			velocity.x = 0
			$AnimationPlayer.play("parado")
	else:
		velocity.x = 0
		$AnimationPlayer.play("parado")

	move_and_slide()

	if (caiu_do_mapa()):
		return

	atualizar_sprite()
	$AreaMarreta.position.x = abs($AreaMarreta.position.x) * direcao
	verificar_contato()

func marretada() -> void:
	atacando = true
	$AnimationPlayer.play("marretada")

# Chamada pela animação "marretada" no quadro em que o punho bate no chão
func impacto() -> void:
	if (morto):
		return

	for corpo in $AreaMarreta.get_overlapping_bodies():
		if (corpo.is_in_group("jogador")):
			corpo.levar_dano()

	Jogo.tocar_som("marretada")
	Jogo.tremer_tela(14)
	Jogo.poeira($AreaMarreta.global_position + Vector2(0, 90), Color(0.6, 0.45, 0.3, 0.9), 24)

	if (em_furia):
		soltar_ondas()

# Duas ondas de choque, uma para cada lado, correndo pelo chão
func soltar_ondas() -> void:
	for lado in [-1, 1]:
		var onda = CENA_ONDA.instantiate()
		onda.direcao = lado
		get_parent().add_child(onda)
		onda.global_position = Vector2($AreaMarreta.global_position.x, global_position.y + 80)

func entrar_em_furia() -> void:
	em_furia          = true
	fator_velocidade  = 0.75
	recarga_marretada = 0.7
	$AnimationPlayer.speed_scale = 1.3
	avisar_fase("anunciar", "FÚRIA!\nPULE AS ONDAS DE CHOQUE!")
	Jogo.tocar_som("furia")
	Jogo.tremer_tela(16)

	# Fica pulsando vermelho
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "modulate", Color(1.4, 0.6, 0.6), 0.3)
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1), 0.3)

# O super chute de fogo tira 3 de vida de uma vez
func levar_super_chute() -> void:
	for i in range(3):
		tempo_invulneravel = 0
		morrer()

func _on_animacao_terminou(nome) -> void:
	if (nome == "marretada"):
		atacando      = false
		tempo_recarga = recarga_marretada
		$AnimationPlayer.play("parado")

# A bola e o carrinho chamam morrer(): no chefão isso só tira um pouco de vida
func morrer() -> void:
	if (morto or tempo_invulneravel > 0):
		return

	vida -= 1
	$BarraVida.value = vida
	tempo_invulneravel = 0.3

	if (vida <= 0):
		remove_from_group("chefao")
		$BarraVida.visible = false
		avisar_fase("chefao_derrotado")
		Jogo.tocar_som("vitoria")
		super()
		return

	Jogo.tocar_som("chute")
	Jogo.poeira(global_position + Vector2(0, -40), Color(1, 0.9, 0.3, 0.9), 10)
	piscar_branco()

	if (vida <= vida_maxima / 2.0 and not em_furia):
		entrar_em_furia()
