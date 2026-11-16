extends CharacterBody2D

var direcao       = 1 #  1 => Direita, -1 => Esquerda
var velocidade    = 800
var tempo_de_vida = 1.5 # segundos até a bola sumir sozinha
var e_super       = false # super chute: bola de fogo que atravessa os adversários

func _ready() -> void:
	if (e_super):
		velocidade    = 1100
		tempo_de_vida = 2.0
		$Sprite2D.scale    *= 1.8
		$Sprite2D.modulate  = Color(1, 0.6, 0.3)
		criar_rastro_de_fogo()
	get_tree().create_timer(tempo_de_vida).timeout.connect(sumir)

func _physics_process(delta: float) -> void:
	velocity.x = velocidade * direcao
	velocity.y = 0
	$Sprite2D.rotation += 15 * direcao * delta

	var colisao = move_and_collide(velocity * delta)
	if (colisao):
		var alvo = colisao.get_collider()
		if (e_super and alvo.has_method("morrer")):
			# Atravessa: acerta o adversário e continua voando
			if (alvo.has_method("levar_super_chute")):
				alvo.levar_super_chute()
			else:
				alvo.morrer()
			add_collision_exception_with(alvo)
			Jogo.tremer_tela(6)
			return
		if (alvo.has_method("morrer")):
			alvo.morrer()
		sumir()

func criar_rastro_de_fogo() -> void:
	var fogo = CPUParticles2D.new()
	fogo.texture              = Jogo.PARTICULA
	fogo.amount               = 60
	fogo.lifetime             = 0.4
	fogo.local_coords         = false # as partículas ficam para trás da bola
	fogo.spread               = 180
	fogo.gravity              = Vector2(0, -150)
	fogo.initial_velocity_min = 10
	fogo.initial_velocity_max = 60
	fogo.scale_amount_min     = 1.0
	fogo.scale_amount_max     = 2.2
	var cores = Gradient.new()
	cores.set_color(0, Color(1, 1, 0.6, 1))
	cores.add_point(0.4, Color(1, 0.5, 0.1, 0.9))
	cores.set_color(cores.get_point_count() - 1, Color(0.6, 0.1, 0.05, 0))
	fogo.color_ramp = cores
	add_child(fogo)
	fogo.position = $Sprite2D.position

func sumir() -> void:
	get_parent().queue_free()
