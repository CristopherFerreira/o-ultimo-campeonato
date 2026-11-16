extends Area2D

# Trampolim: quando o jogador cai em cima, é lançado bem alto

@export var forca = 1300.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if (not body.is_in_group("jogador") or body.velocity.y < 0):
		return
	body.impulsionar(forca)
	Jogo.tocar_som("pulo", 4)
	# Lona afunda e volta
	$Sprite2D.texture = load("res://graficos/trampolim_apertado.png")
	await get_tree().create_timer(0.15).timeout
	$Sprite2D.texture = load("res://graficos/trampolim.png")
