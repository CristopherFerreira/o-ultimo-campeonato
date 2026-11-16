extends Area2D

# Arame farpado no chão: machuca quem encostar (tem que pular por cima)

@export var largura = 128.0

func _ready() -> void:
	$Visual.size = Vector2(largura, 28)
	$Visual.position = Vector2(-largura / 2, -28)
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	$CollisionShape2D.shape.size = Vector2(largura - 10, 20)

func _physics_process(delta: float) -> void:
	for corpo in get_overlapping_bodies():
		if (corpo.is_in_group("jogador")):
			corpo.levar_dano()
