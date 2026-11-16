extends Area2D

# Chinelo arremessado pelo torcedor rival: voa em arco (com gravidade)

var velocidade = Vector2.ZERO
var gravidade  = 900.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	velocidade.y += gravidade * delta
	position += velocidade * delta
	rotation += 14 * delta

func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("jogador")):
		body.levar_dano()
	Jogo.poeira(global_position, Color(0.4, 0.7, 1, 0.9), 8)
	queue_free()
