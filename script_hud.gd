extends CanvasLayer

# O HUD fica com process_mode = Always, então continua funcionando com o jogo pausado

func _ready() -> void:
	$Tela/Mensagem.visible  = false
	$Tela/MenuPausa.visible = false
	%Continuar.pressed.connect(alternar_pausa)
	Jogo.empolgacao_mudou.connect(atualizar_torcida)
	atualizar_torcida(Jogo.empolgacao)
	%MenuPrincipal.pressed.connect(ir_para_menu)

func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_cancel") and get_parent().get("jogo_acabou") == false):
		alternar_pausa()

const CORACAO = preload("res://graficos/coracao.png")

var tween_barra

func atualizar_objetivo(texto, cor = Color.WHITE) -> void:
	%Objetivo.text = texto
	%Objetivo.add_theme_color_override("font_color", cor)
	# o ícone de figurinha só aparece quando o objetivo é colecionar figurinhas
	$Tela/Topo/Linha/PainelObjetivo/Linha/Icone.visible = texto.contains("FIGURINHA")

# Medidor da torcida: quando enche, avisa que o super chute está pronto
func atualizar_torcida(valor) -> void:
	%BarraTorcida.max_value = Jogo.EMPOLGACAO_MAXIMA
	create_tween().tween_property(%BarraTorcida, "value", float(valor), 0.2)

	var cheio = Jogo.super_chute_pronto()
	%AvisoSuper.visible = cheio
	if (tween_barra):
		tween_barra.kill()
		%BarraTorcida.modulate = Color.WHITE
	if (cheio):
		tween_barra = create_tween().set_loops()
		tween_barra.tween_property(%BarraTorcida, "modulate", Color(1.6, 1.2, 0.6), 0.25)
		tween_barra.tween_property(%BarraTorcida, "modulate", Color.WHITE, 0.25)

func atualizar(nome_fase, vidas, pontos) -> void:
	%NomeFase.text = nome_fase
	%Pontos.text = "%d PTS" % pontos
	%QtdBolas.text = "x %d" % Jogo.bolas
	%QtdBolas.add_theme_color_override("font_color", Color(1, 0.4, 0.3) if Jogo.bolas == 0 else Color.WHITE)

	# Um coração para cada vida
	for filho in %Vidas.get_children():
		filho.queue_free()
	for i in range(vidas):
		var coracao = TextureRect.new()
		coracao.texture = CORACAO
		coracao.custom_minimum_size = Vector2(30, 27)
		coracao.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coracao.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		%Vidas.add_child(coracao)

# Se duracao for 0, a mensagem fica na tela até ser trocada
func mostrar_mensagem(texto, duracao = 0.0) -> void:
	$Tela/Mensagem.text    = texto
	$Tela/Mensagem.visible = true
	if (duracao > 0):
		get_tree().create_timer(duracao).timeout.connect(esconder_mensagem.bind(texto))

func esconder_mensagem(texto) -> void:
	if ($Tela/Mensagem.text == texto):
		$Tela/Mensagem.visible = false

func alternar_pausa() -> void:
	get_tree().paused = not get_tree().paused
	$Tela/MenuPausa.visible = get_tree().paused
	if (get_tree().paused):
		%Continuar.grab_focus()

func ir_para_menu() -> void:
	get_tree().paused = false
	Jogo.voltar_ao_menu()
