extends CharacterBody2D

# Script base de todos os inimigos. O árbitro, o goleiro e o chefão
# herdam deste script (extends "res://script_inimigo.gd") e só mudam o que precisam.

var velocidade         = 150
var fator_velocidade   = 1.0 # cada tipo de inimigo pode ser mais lento ou mais rápido que o normal
var gravidade          = 30
var direcao            = -1
var distancia_patrulha = 200 # quanto ele anda para cada lado a partir de onde começou
var distancia_sensor   = 35  # onde fica o sensor que procura buraco à frente
var posicao_inicial    = 0.0
var morto              = false
var pontos             = 100
var animacao_movimento = "correndo"
var sprite_olha_para_direita = true # o desenho original está virado para a direita?

func _ready() -> void:
	add_to_group("inimigos")
	posicao_inicial = global_position.x
	$AnimationPlayer.play(animacao_movimento)

	# O jogador genérico (feito com o sprite do jogador) veste o uniforme do time rival
	if ($Sprite2D.texture.resource_path.ends_with("jogador_pixel.png")):
		Jogo.vestir($Sprite2D, Jogo.selecao_rival())

func _physics_process(delta: float) -> void:
	if (morto):
		return

	velocity.y += gravidade
	velocity.x = velocidade * fator_velocidade * direcao
	move_and_slide()

	if (caiu_do_mapa()):
		return

	patrulhar()
	atualizar_sprite()
	verificar_contato()

func caiu_do_mapa() -> bool:
	if (global_position.y > 1000):
		get_parent().queue_free()
		return true
	return false

# Patrulha: vira ao bater numa parede, ao chegar na beirada de um buraco
# ou ao se afastar demais de onde começou
func patrulhar() -> void:
	if (is_on_wall() or not tem_chao_a_frente()):
		direcao = -direcao
	elif (global_position.x > posicao_inicial + distancia_patrulha):
		direcao = -1
	elif (global_position.x < posicao_inicial - distancia_patrulha):
		direcao = 1

func tem_chao_a_frente() -> bool:
	$SensorChao.position.x = distancia_sensor * direcao
	$SensorChao.force_raycast_update()
	return (not is_on_floor()) or $SensorChao.is_colliding()

func atualizar_sprite() -> void:
	if (sprite_olha_para_direita):
		$Sprite2D.flip_h = (direcao == -1)
	else:
		$Sprite2D.flip_h = (direcao == 1)

	# Sprite recortado do sheet do jogador: cada quadro tem uma altura diferente
	if ($Sprite2D.region_enabled):
		$Sprite2D.offset.y = (115 - $Sprite2D.region_rect.size.y) / 2

# Encostou no jogador: se ele estiver dando carrinho/cabeçada ou caindo em cima da
# cabeça do inimigo, o inimigo perde. Senão, o jogador leva dano.
func verificar_contato() -> void:
	for corpo in $AreaDano.get_overlapping_bodies():
		if (corpo.is_in_group("jogador")):
			if (corpo.atacando_de_perto()):
				morrer()
			elif (corpo.velocity.y > 50 and corpo.global_position.y < global_position.y - 30):
				corpo.quicar()
				Jogo.empolgar(10) # pisão vale um bônus de empolgação
				morrer()
			else:
				corpo.levar_dano()

# Devolve o jogador se ele estiver perto (na horizontal) e mais ou menos na mesma altura
func procurar_jogador(alcance) -> Node2D:
	var jogador = get_tree().get_first_node_in_group("jogador")
	if (jogador == null):
		return null

	var distancia = jogador.global_position - global_position
	if (abs(distancia.x) < alcance and abs(distancia.y) < 150):
		return jogador
	return null

func virar_para(alvo) -> void:
	if (alvo.global_position.x > global_position.x):
		direcao = 1
	else:
		direcao = -1

func morrer() -> void:
	if (morto):
		return
	morto = true

	avisar_fase("adicionar_pontos", pontos)
	avisar_fase("inimigo_derrotado") # conta para o desafio "derrotar"
	Jogo.empolgar(20) # a torcida vibra
	piscar_branco()
	Jogo.tocar_som("inimigo")
	Jogo.poeira(global_position, Color(1, 1, 0.8, 0.9), 16)
	Jogo.texto_flutuante(global_position + Vector2(0, -70), "+%d" % pontos)

	# 35% de chance de deixar uma bola (munição) no chão
	if (randf() < 0.35):
		var item = load("res://cena_item.tscn").instantiate()
		item.tipo = "bola"
		get_parent().get_parent().add_child.call_deferred(item)
		item.position = global_position + Vector2(0, -10)

	$CollisionShape2D.set_deferred("disabled", true)
	$AnimationPlayer.stop()

	# Sobe um pouco e desaparece
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 80, 0.4)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(get_parent().queue_free)

func piscar_branco() -> void:
	var tween = create_tween()
	tween.tween_method(func(v): $Sprite2D.material.set_shader_parameter("lampejo", v), 1.0, 0.0, 0.25)

# Chama uma função da cena da fase (se ela existir), ex: adicionar_pontos
func avisar_fase(metodo, valor = null) -> void:
	var fase = get_tree().current_scene
	if (fase.has_method(metodo)):
		if (valor == null):
			fase.call(metodo)
		else:
			fase.call(metodo, valor)
