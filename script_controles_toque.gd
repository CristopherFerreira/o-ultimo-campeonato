extends Control

# Controles de toque para celular/tablet. Só são criados em aparelhos com tela de toque.
# Cada botão "aperta" a mesma ação do teclado (Input Map), então o jogador
# funciona igual no teclado e no toque, sem nenhuma mudança no script dele.

const PASTA = "res://graficos/toque/"

var botao_super : TouchScreenButton
var aviso_girar : Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS # o botão de pausa precisa funcionar com o jogo pausado

	if (not DisplayServer.is_touchscreen_available()):
		queue_free()
		return

	# Esquerda: andar (dá para deslizar o dedo de um botão para o outro)
	var esquerda = canto(Control.PRESET_BOTTOM_LEFT)
	criar_botao(esquerda, "esquerda", "ir_para_esquerda", Vector2(24, -178), true)
	criar_botao(esquerda, "direita",  "ir_para_direita",  Vector2(190, -178), true)

	# Direita: pulo e ataques
	var direita = canto(Control.PRESET_BOTTOM_RIGHT)
	criar_botao(direita, "pulo",     "pular",    Vector2(-186, -190))
	criar_botao(direita, "chute",    "chutar",   Vector2(-330, -150))
	criar_botao(direita, "carrinho", "carrinho", Vector2(-160, -330))
	criar_botao(direita, "cabecada", "cabecada", Vector2(-300, -290))
	botao_super = criar_botao(direita, "super", "super_chute", Vector2(-445, -135))

	# Topo, no meio: pausa (a barra do HUD fica nos cantos). Chama o HUD direto:
	# o evento de ação não chega no _unhandled_input do HUD vindo de um TouchScreenButton
	var topo = canto(Control.PRESET_CENTER_TOP)
	var pausa = criar_botao(topo, "pausa", "", Vector2(-40, 12))
	pausa.pressed.connect(pausar)

	# O super chute só aparece quando o medidor da torcida enche
	Jogo.empolgacao_mudou.connect(func(_v): botao_super.visible = Jogo.super_chute_pronto())
	botao_super.visible = Jogo.super_chute_pronto()

	criar_aviso_girar()
	get_viewport().size_changed.connect(verificar_orientacao)
	verificar_orientacao()

# Um Control vazio preso num canto da tela: os botões ficam posicionados a partir dele
func canto(preset) -> Control:
	var c = Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	c.set_anchors_and_offsets_preset(preset)
	return c

func criar_botao(pai, nome, acao, posicao, deslizar = false) -> TouchScreenButton:
	var b = TouchScreenButton.new()
	b.texture_normal  = load(PASTA + nome + ".png")
	b.texture_pressed = load(PASTA + nome + "_apertado.png")
	b.action          = acao
	b.passby_press    = deslizar
	b.position        = posicao
	pai.add_child(b)
	return b

func pausar() -> void:
	var hud = get_parent().get_parent() # Tela -> HUD
	if (get_tree().current_scene.get("jogo_acabou") == false):
		hud.alternar_pausa()

# Celular em pé: pede para girar (o jogo é feito para tela deitada)
func criar_aviso_girar() -> void:
	aviso_girar = ColorRect.new()
	aviso_girar.color = Color(0, 0, 0, 0.85)
	aviso_girar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(aviso_girar)
	aviso_girar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var texto = Label.new()
	texto.text = "Gire o celular\npara jogar"
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 56)
	aviso_girar.add_child(texto)
	texto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func verificar_orientacao() -> void:
	var tamanho = get_viewport().get_visible_rect().size
	aviso_girar.visible = tamanho.y > tamanho.x
