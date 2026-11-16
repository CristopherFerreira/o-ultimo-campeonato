extends Area2D

# Onda de choque da marretada do chefão (2ª fase): corre pelo chão e
# tira uma vida se o jogador não pular por cima dela

var direcao       = 1
var velocidade    = 480
var tempo_de_vida = 1.6

func _ready() -> void:
	$Sprite2D.flip_h = (direcao == -1)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(tempo_de_vida).timeout.connect(queue_free)
	
	# Aparece crescendo
	scale = Vector2(0.3, 0.3)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.15)

func _physics_process(delta: float) -> void:
	position.x += velocidade * direcao * delta
	$Sprite2D.modulate.a = 0.75 + 0.25 * sin(Time.get_ticks_msec() / 40.0)

func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("jogador")):
		body.levar_dano()
