extends "res://script_inimigo.gd"

# VAR: monitor-robô voador. Segue o jogador pelo alto; quando fica em cima dele,
# "analisa o lance" (tela vermelha piscando) e mergulha. Depois sobe de novo.
# Dá para derrotar com a bola, o carrinho ou pulando nele quando estiver baixo.

var altura_voo     = 200   # quanto voa acima do jogador
var alcance_visao  = 650
var estado         = "voando" # "voando", "analisando", "mergulhando", "subindo"
var tempo_estado   = 1.0
var altura_inicial = 0.0
var y_alvo         = 0.0
var tempo          = 0.0

func _ready() -> void:
	animacao_movimento = "voando"
	pontos             = 200
	super()
	altura_inicial = global_position.y

func _physics_process(delta: float) -> void:
	if (morto):
		return
	
	tempo += delta
	tempo_estado -= delta
	var jogador = procurar_jogador_no_ar()
	
	match estado:
		"voando":
			if (jogador != null):
				# Persegue pelo alto
				var dx = jogador.global_position.x - global_position.x
				velocity.x = move_toward(velocity.x, sign(dx) * velocidade * 1.1, 25)
				var alvo_y = jogador.global_position.y - altura_voo + sin(tempo * 3) * 10
				velocity.y = (alvo_y - global_position.y) * 3
				direcao = 1 if dx > 0 else -1
				if (abs(dx) < 50 and tempo_estado <= 0):
					estado = "analisando"
					tempo_estado = 0.7
					$AnimationPlayer.play("alerta")
					Jogo.tocar_som("apito", -6)
			else:
				# Sem jogador por perto: flutua indo e voltando
				velocity.x = velocidade * 0.5 * direcao
				velocity.y = (altura_inicial + sin(tempo * 2) * 15 - global_position.y) * 3
				if (abs(global_position.x - posicao_inicial) > distancia_patrulha):
					direcao = -1 if global_position.x > posicao_inicial else 1
		"analisando":
			velocity = Vector2(sin(tempo * 60) * 60, 0) # treme enquanto analisa
			if (tempo_estado <= 0):
				estado = "mergulhando"
				y_alvo = global_position.y + altura_voo + 40
		"mergulhando":
			velocity = Vector2(0, 950)
			if (global_position.y >= y_alvo or is_on_floor()):
				estado = "subindo"
				tempo_estado = 0.3
				$AnimationPlayer.play("voando")
		"subindo":
			velocity = Vector2(0, -380)
			if (tempo_estado <= 0 and (jogador == null or global_position.y <= jogador.global_position.y - altura_voo)):
				estado = "voando"
				tempo_estado = 1.8 # espera antes do próximo mergulho
	
	move_and_slide()
	atualizar_sprite()
	verificar_contato()

# Como ele voa alto, procura o jogador com uma "janela" vertical maior
func procurar_jogador_no_ar() -> Node2D:
	var jogador = get_tree().get_first_node_in_group("jogador")
	if (jogador == null):
		return null
	var d = jogador.global_position - global_position
	if (abs(d.x) < alcance_visao and d.y > -150 and d.y < 450):
		return jogador
	return null

# O VAR não espelha o desenho (senão a palavra "VAR" fica ao contrário)
func atualizar_sprite() -> void:
	pass
