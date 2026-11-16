extends CharacterBody2D

const CENA_BOLA = preload("res://cena_bola.tscn")

var velocidade  = 500
var gravidade   = 30
var forca_pulo  = 800
var pode_chutar = true
var direcao     = 1 # 1 para direita, -1 para esquerda

# Carrinho (ataque de curto alcance)
var velocidade_carrinho = 900
var no_carrinho         = false
var pode_dar_carrinho   = true

# Cabeçada (ataque de curto alcance, funciona no chão e no ar)
var velocidade_cabecada = 650
var na_cabecada         = false
var pode_dar_cabecada   = true

# Dano e queda
var invulneravel    = false
var posicao_inicial = Vector2.ZERO
var limite_queda    = 1000 # abaixo dessa altura o jogador caiu do mapa

# Pulo mais "gostoso": dá para pular logo depois de sair da beirada (coyote time)
# e o aperto do botão um pouco antes de tocar o chão também vale (buffer)
var escorregadio = false # na neve o jogador acelera e freia devagar (a fase liga isso)
var tempo_atordoado = 0.0 # "IMPEDIMENTO!": fica alguns instantes sem controle

var tempo_coyote = 0.0
var tempo_buffer = 0.0
var estava_no_chao = true

# Enquanto for maior que zero, a animação atual (chute/carrinho) não é trocada
var tempo_animacao_travada = 0.0

func _ready() -> void:
	add_to_group("jogador")
	posicao_inicial = global_position
	Jogo.vestir($Sprite2D, Jogo.selecao) # uniforme da seleção escolhida no menu

func _physics_process(delta: float) -> void:
	velocity.y += gravidade
	tempo_atordoado -= delta

	if (tempo_atordoado > 0):
		velocity.x = move_toward(velocity.x, 0, 20) # tonto: só vai parando
	elif (no_carrinho):
		velocity.x = velocidade_carrinho * direcao
	elif (na_cabecada):
		velocity.x = velocidade_cabecada * direcao
	else:
		var alvo_x = 0.0

		if (Input.is_action_pressed("ir_para_esquerda")):
			alvo_x = -velocidade
			direcao = -1

		if (Input.is_action_pressed("ir_para_direita")):
			alvo_x = velocidade
			direcao = 1

		if (escorregadio and is_on_floor()):
			velocity.x = move_toward(velocity.x, alvo_x, 14) # desliza no gelo
		else:
			velocity.x = alvo_x

		if (is_on_floor()):
			tempo_coyote = 0.1
		else:
			tempo_coyote -= delta

		if (Input.is_action_just_pressed("pular")):
			tempo_buffer = 0.12
		else:
			tempo_buffer -= delta

		if (tempo_buffer > 0 and tempo_coyote > 0):
			pular()

		# Soltou o botão no meio da subida: o pulo fica mais baixo
		if (Input.is_action_just_released("pular") and velocity.y < 0):
			velocity.y *= 0.5

		if (Input.is_action_pressed("chutar") and pode_chutar):
			chutar()

		# SHIFT + ESPAÇO também "aperta" o carrinho (ESPAÇO), por isso a cabeçada é testada antes
		if (Input.is_action_just_pressed("cabecada")):
			if (pode_dar_cabecada):
				dar_cabecada()
		elif (Input.is_action_just_pressed("carrinho") and pode_dar_carrinho and is_on_floor()):
			dar_carrinho()

		if (Input.is_action_just_pressed("super_chute") and Jogo.super_chute_pronto()):
			super_chute()

	move_and_slide()

	# Poeirinha ao aterrissar
	if (is_on_floor() and not estava_no_chao):
		Jogo.poeira(global_position + Vector2(0, 55), Color(0.85, 0.8, 0.7, 0.8), 8)
		esticar(Vector2(1.04, 0.96)) # "amassa" ao cair (sutil, para não deformar o rosto)
	estava_no_chao = is_on_floor()

	atualizar_sombra()

	if (global_position.y > limite_queda):
		cair_do_mapa()

func _process(delta: float) -> void:
	$Sprite2D.flip_h = (direcao == -1)
	$FogoSuper.emitting = Jogo.super_chute_pronto() # pega fogo quando o super chute está pronto

	if (tempo_animacao_travada > 0):
		tempo_animacao_travada -= delta
		return

	if (not is_on_floor()):
		$AnimationPlayer.play("pulando")
	elif (velocity.x != 0):
		$AnimationPlayer.play("correndo")
	else:
		$AnimationPlayer.play("parado")

func pular() -> void:
	velocity.y   = -forca_pulo
	tempo_buffer = 0
	tempo_coyote = 0
	Jogo.tocar_som("pulo")
	esticar(Vector2(0.96, 1.04)) # "estica" ao pular (sutil, para não deformar o rosto)

# Deforma o sprite rapidinho e volta ao normal (squash & stretch)
func esticar(escala) -> void:
	$Sprite2D.scale = escala
	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# A sombra fica sempre no chão logo abaixo do jogador e diminui quando ele sobe
func atualizar_sombra() -> void:
	var espaco = get_world_2d().direct_space_state
	var raio = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 700), 1)
	var resultado = espaco.intersect_ray(raio)
	$Sombra.visible = not resultado.is_empty()
	if ($Sombra.visible):
		var altura = resultado.position.y - (global_position.y + 56)
		$Sombra.global_position = resultado.position + Vector2(0, -3)
		$Sombra.scale = Vector2.ONE * clamp(1.0 - altura / 400.0, 0.3, 1.0)

# Trampolim: lança o jogador bem alto
func impulsionar(forca) -> void:
	velocity.y = -forca
	tempo_coyote = 0
	esticar(Vector2(0.94, 1.06))

# Impedimento do bandeirinha: fica tonto por alguns instantes
func atordoar(segundos) -> void:
	tempo_atordoado = segundos
	var tween = create_tween()
	for i in range(4):
		tween.tween_property($Sprite2D, "rotation", 0.15, 0.08)
		tween.tween_property($Sprite2D, "rotation", -0.15, 0.08)
	tween.tween_property($Sprite2D, "rotation", 0.0, 0.08)

# Pisou na cabeça de um inimigo: dá um quique para cima
func quicar() -> void:
	velocity.y = -forca_pulo * 0.7

func tocar_animacao(nome, duracao) -> void:
	$AnimationPlayer.stop()
	$AnimationPlayer.play(nome)
	tempo_animacao_travada = duracao

func chutar() -> void:
	pode_chutar = false

	# Sem munição: não chuta (pegue itens de bola pelo caminho)
	if (Jogo.bolas <= 0):
		Jogo.texto_flutuante(global_position + Vector2(-50, -90), "SEM BOLAS!", Color(1, 0.4, 0.3))
		await get_tree().create_timer(0.6).timeout
		pode_chutar = true
		return
	Jogo.bolas -= 1
	avisar_fase("atualizar_hud")

	tocar_animacao("chutando", 0.3)
	Jogo.tocar_som("chute")

	lancar_bola(false)

	await get_tree().create_timer(0.3).timeout
	pode_chutar = true

# Super chute: bola de fogo que atravessa todos os adversários
func super_chute() -> void:
	Jogo.empolgar(-Jogo.EMPOLGACAO_MAXIMA)
	tocar_animacao("chutando", 0.4)
	Jogo.tocar_som("super")
	Jogo.tremer_tela(10)
	lancar_bola(true)

func lancar_bola(e_super) -> void:
	var pos_x = abs($Marker2D.position.x)
	$Marker2D.position.x = pos_x * direcao

	var obj_bola = CENA_BOLA.instantiate()
	obj_bola.get_node("CharacterBody2D").direcao  = direcao
	obj_bola.get_node("CharacterBody2D").e_super  = e_super
	get_parent().add_child(obj_bola)
	obj_bola.global_position = $Marker2D.global_position

func dar_carrinho() -> void:
	no_carrinho = true
	pode_dar_carrinho = false
	tocar_animacao("carrinho", 0.5)
	Jogo.tocar_som("carrinho")
	Jogo.poeira(global_position + Vector2(0, 50), Color(0.5, 0.8, 0.4, 0.9), 10)

	await get_tree().create_timer(0.5).timeout
	no_carrinho = false

	await get_tree().create_timer(0.3).timeout
	pode_dar_carrinho = true

func dar_cabecada() -> void:
	na_cabecada = true
	pode_dar_cabecada = false
	tocar_animacao("pulando", 0.3)
	Jogo.tocar_som("cabecada")

	# Inclina o corpo para frente e volta (a testada)
	var tween = create_tween()
	tween.tween_property($Sprite2D, "rotation", 0.35 * direcao, 0.08)
	tween.tween_property($Sprite2D, "rotation", 0.0, 0.17)

	await get_tree().create_timer(0.25).timeout
	na_cabecada = false

	await get_tree().create_timer(0.35).timeout
	pode_dar_cabecada = true

# Golpe de curto alcance ativo (carrinho ou cabeçada): derruba o inimigo que encostar
func atacando_de_perto() -> bool:
	return no_carrinho or na_cabecada

func levar_dano() -> void:
	if (invulneravel):
		return

	invulneravel = true
	velocity.y = -400
	Jogo.tocar_som("dano")
	Jogo.tremer_tela(8)
	Jogo.empolgar(-35) # a torcida desanima
	piscar_branco()
	avisar_fase("perder_vida")

	# Pisca enquanto está invulnerável
	var tween = create_tween().set_loops(6)
	tween.tween_property($Sprite2D, "modulate:a", 0.2, 0.1)
	tween.tween_property($Sprite2D, "modulate:a", 1.0, 0.1)

	await get_tree().create_timer(1.2).timeout
	invulneravel = false

func piscar_branco() -> void:
	var tween = create_tween()
	tween.tween_method(func(v): $Sprite2D.material.set_shader_parameter("lampejo", v), 1.0, 0.0, 0.3)

func cair_do_mapa() -> void:
	Jogo.tocar_som("dano")
	global_position = posicao_inicial
	velocity = Vector2.ZERO
	avisar_fase("perder_vida")

# Chama uma função da cena da fase (se ela existir), ex: perder_vida
func avisar_fase(metodo) -> void:
	var fase = get_tree().current_scene
	if (fase.has_method(metodo)):
		fase.call(metodo)
