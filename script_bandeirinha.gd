extends "res://script_inimigo.gd"

# Bandeirinha (assistente do árbitro): patrulha a lateral. Quando vê o jogador,
# levanta a bandeira e avança correndo. Se pegar o jogador: "IMPEDIMENTO!"
# (tira uma vida e deixa o jogador tonto por um instante).

var alcance_visao  = 420
var velocidade_ataque = 520
var tempo_recarga  = 0.0
var estado         = "patrulha" # "patrulha", "bandeira" (avisando) ou "corrida"
var tempo_estado   = 0.0

func _ready() -> void:
	animacao_movimento = "andando"
	fator_velocidade   = 0.8
	pontos             = 150
	super()

func _physics_process(delta: float) -> void:
	if (morto):
		return
	
	tempo_recarga -= delta
	tempo_estado  -= delta
	velocity.y += gravidade
	
	match estado:
		"patrulha":
			velocity.x = velocidade * fator_velocidade * direcao
			var jogador = procurar_jogador(alcance_visao)
			if (jogador != null and tempo_recarga <= 0):
				# Levanta a bandeira e apita: aviso antes de correr
				virar_para(jogador)
				estado = "bandeira"
				tempo_estado = 0.5
				velocity.x = 0
				$Bandeira.rotation = -0.6
				Jogo.tocar_som("apito", -3)
				Jogo.texto_flutuante(global_position + Vector2(-40, -110), "!", Color(1, 0.85, 0.2))
		"bandeira":
			velocity.x = 0
			$Bandeira.rotation = -0.6 + sin(tempo_estado * 40.0) * 0.3 # balançando a bandeira
			if (tempo_estado <= 0):
				estado = "corrida"
				tempo_estado = 0.9
				$AnimationPlayer.speed_scale = 2.0
		"corrida":
			velocity.x = velocidade_ataque * direcao
			if (not tem_chao_a_frente() or is_on_wall()):
				velocity.x = 0 # não corre para o buraco
			if (tempo_estado <= 0):
				terminar_corrida()
	
	move_and_slide()
	
	if (caiu_do_mapa()):
		return
	if (estado == "patrulha"):
		patrulhar()
	
	atualizar_sprite()
	$Bandeira.position.x = abs($Bandeira.position.x) * direcao
	$Bandeira.flip_h = (direcao == -1)
	verificar_contato()

func terminar_corrida() -> void:
	estado = "patrulha"
	tempo_recarga = 2.0
	$Bandeira.rotation = 0.5
	$AnimationPlayer.speed_scale = 1.0

# Encostou no jogador durante a corrida: impedimento!
func verificar_contato() -> void:
	for corpo in $AreaDano.get_overlapping_bodies():
		if (corpo.is_in_group("jogador") and estado == "corrida" and not corpo.atacando_de_perto()
				and not (corpo.velocity.y > 50 and corpo.global_position.y < global_position.y - 30)):
			if (not corpo.invulneravel):
				Jogo.texto_flutuante(corpo.global_position + Vector2(-90, -100), "IMPEDIMENTO!", Color(1, 0.85, 0.2))
				corpo.atordoar(0.8)
			corpo.levar_dano()
			terminar_corrida()
			return
	super()
