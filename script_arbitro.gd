extends "res://script_inimigo.gd"

# Árbitro: anda devagar e, quando vê o jogador, para e arremessa um cartão

const CENA_CARTAO = preload("res://cena_cartao.tscn")

var alcance_arremesso = 450
var tempo_recarga     = 0.0 # segundos até poder arremessar de novo
var arremessando      = false

func _ready() -> void:
	animacao_movimento = "andando"
	fator_velocidade   = 0.5
	pontos             = 150
	super()
	$AnimationPlayer.animation_finished.connect(_on_animacao_terminou)

func _physics_process(delta: float) -> void:
	if (morto):
		return

	tempo_recarga -= delta
	velocity.y += gravidade

	if (arremessando):
		velocity.x = 0
	else:
		velocity.x = velocidade * fator_velocidade * direcao

	move_and_slide()

	if (caiu_do_mapa()):
		return

	if (not arremessando):
		patrulhar()
		var jogador = procurar_jogador(alcance_arremesso)
		if (jogador != null and tempo_recarga <= 0):
			arremessar(jogador)

	atualizar_sprite()
	verificar_contato()

func arremessar(jogador) -> void:
	arremessando = true
	virar_para(jogador)
	$AnimationPlayer.play("arremessando")
	Jogo.tocar_som("apito", -4)

# Chamada pela própria animação "arremessando", no quadro em que o braço vai para frente
func soltar_cartao() -> void:
	if (morto):
		return

	var cartao = CENA_CARTAO.instantiate()
	cartao.direcao = direcao
	cartao.amarelo = randf() < 0.5 # sorteia amarelo ou vermelho
	get_parent().add_child(cartao)
	cartao.global_position = global_position + Vector2(40 * direcao, -25)
	Jogo.tocar_som("arremesso")

func _on_animacao_terminou(nome) -> void:
	if (nome == "arremessando"):
		arremessando  = false
		tempo_recarga = 2.0
		$AnimationPlayer.play("andando")
