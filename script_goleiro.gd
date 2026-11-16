extends "res://script_inimigo.gd"

# Goleiro bravo: patrulha; quando vê o jogador, PERSEGUE dando saltos na direção dele
# e, bem de perto, se joga em cima dele (bote)

var alcance_bote    = 280
var alcance_visao   = 520  # a partir daqui ele começa a perseguir
var tempo_salto     = 0.0  # intervalo entre os saltos da perseguição
var velocidade_bote = 750
var tempo_recarga   = 0.0
var dando_bote      = false

func _ready() -> void:
	animacao_movimento = "correndo"
	pontos             = 150
	super()
	$AnimationPlayer.animation_finished.connect(_on_animacao_terminou)

func _physics_process(delta: float) -> void:
	if (morto):
		return

	tempo_recarga -= delta
	tempo_salto   -= delta
	velocity.y += gravidade

	var jogador = procurar_jogador(alcance_visao)

	if (dando_bote):
		# Vai perdendo velocidade durante o pulo, e não se joga no buraco
		velocity.x = move_toward(velocity.x, 0, 12)
		if (not tem_chao_a_frente()):
			velocity.x = 0
	elif (jogador != null):
		# Perseguição: vira para o jogador, corre mais rápido e vai saltando
		virar_para(jogador)
		velocity.x = velocidade * 1.35 * direcao
		if (not tem_chao_a_frente()):
			velocity.x = 0 # não se joga no buraco
		elif (is_on_floor() and tempo_salto <= 0):
			velocity.y = -480
			tempo_salto = 0.9
	else:
		velocity.x = velocidade * fator_velocidade * direcao

	move_and_slide()

	if (caiu_do_mapa()):
		return

	if (not dando_bote):
		if (jogador == null):
			patrulhar()
		elif (tempo_recarga <= 0 and procurar_jogador(alcance_bote) != null):
			dar_bote(jogador)

	atualizar_sprite()
	verificar_contato()

func dar_bote(jogador) -> void:
	dando_bote = true
	virar_para(jogador)
	velocity.x = velocidade_bote * direcao
	velocity.y = -300
	$AnimationPlayer.play("atacando")
	Jogo.tocar_som("carrinho", -3)

func _on_animacao_terminou(nome) -> void:
	if (nome == "atacando"):
		dando_bote    = false
		tempo_recarga = 1.5
		$AnimationPlayer.play("correndo")
