extends Node2D

# Plataforma flutuante. O visual muda conforme o lugar (tema) da fase.
# Se "deslocamento" for diferente de zero, ela fica indo e voltando.

@export_enum("estadio", "varzea", "praia", "neve", "cidade", "obra") var tema = "estadio"
@export var deslocamento = Vector2.ZERO # para onde ela anda (ex: Vector2(300, 0) = 300 px para a direita)
@export var duracao      = 2.5          # segundos para ir (e o mesmo para voltar)
@export var desmorona    = false        # cai logo depois que o jogador pisa (e volta depois)

var caindo = false

var tempo = 0.0
var posicao_inicial = Vector2.ZERO

func _ready() -> void:
	if (tema != "estadio"):
		$Corpo/Visual.texture = load("res://graficos/plataforma_%s.png" % tema)
	posicao_inicial = $Corpo.position
	if (desmorona):
		$Corpo/Visual.modulate = Color(1, 0.8, 0.7) # um pouco avermelhada: é frágil

func _physics_process(delta: float) -> void:
	if (desmorona and not caindo):
		verificar_pisada()
	if (deslocamento == Vector2.ZERO):
		return
	tempo += delta
	# Vai e volta suavemente (0 -> 1 -> 0) usando seno
	var t = (1.0 - cos(tempo / duracao * PI)) / 2.0
	$Corpo.position = posicao_inicial + deslocamento * t

# Plataforma que desmorona: treme, cai e volta alguns segundos depois
func verificar_pisada() -> void:
	var jogador = get_tree().get_first_node_in_group("jogador")
	if (jogador == null or not jogador.is_on_floor()):
		return
	var d = jogador.global_position - $Corpo.global_position
	if (abs(d.x) < 125 and d.y < -40 and d.y > -80):
		desmoronar()

func desmoronar() -> void:
	caindo = true
	var tween = create_tween()
	for i in range(6): # treme
		tween.tween_property($Corpo/Visual, "position:x", 4.0, 0.04)
		tween.tween_property($Corpo/Visual, "position:x", -4.0, 0.04)
	tween.tween_callback(func():
		$Corpo/CollisionShape2D.set_deferred("disabled", true)
		Jogo.poeira($Corpo.global_position, Color(0.7, 0.6, 0.5), 12))
	tween.tween_property($Corpo/Visual, "position:y", 300.0, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property($Corpo/Visual, "modulate:a", 0.0, 0.6)
	tween.tween_interval(2.5)
	tween.tween_callback(func(): # volta ao lugar
		$Corpo/Visual.position = Vector2(0, 3)
		$Corpo/CollisionShape2D.set_deferred("disabled", false)
		caindo = false)
	tween.tween_property($Corpo/Visual, "modulate:a", 1.0, 0.3)
