extends Control

# Cores originais do uniforme (para a "CLÁSSICA", que não troca de cor)
const CAMISA_ORIGINAL  = Color(0.12, 0.3, 0.75)
const DETALHE_ORIGINAL = Color(1.0, 0.85, 0.1)

func _ready() -> void:
	$PainelComoJogar.visible = false
	$PainelOpcoes.visible = false
	Jogo.tocar_musica("menu")
	%Jogar.pressed.connect(Jogo.novo_jogo)
	%ComoJogar.pressed.connect(abrir_como_jogar)
	%Voltar.pressed.connect(fechar_como_jogar)
	%Opcoes.pressed.connect(abrir_opcoes)
	%VoltarOpcoes.pressed.connect(fechar_opcoes)
	%Sair.pressed.connect(get_tree().quit)
	
	%SelecaoAnterior.pressed.connect(trocar_selecao.bind(-1))
	%SelecaoProxima.pressed.connect(trocar_selecao.bind(1))
	
	mostrar_selecao(false)
	animar_titulo()
	%Jogar.grab_focus()

# Título "respirando" devagar
func animar_titulo() -> void:
	await get_tree().process_frame # espera o layout calcular o tamanho
	%Titulo.pivot_offset = %Titulo.size / 2
	var tween = create_tween().set_loops()
	tween.tween_property(%Titulo, "scale", Vector2(1.03, 1.03), 1.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(%Titulo, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_SINE)

# ---------- Escolha da seleção (uniforme do jogador) ----------

func trocar_selecao(passo) -> void:
	Jogo.selecao = posmod(Jogo.selecao + passo, Jogo.SELECOES.size())
	Jogo.tocar_som("pulo")
	mostrar_selecao(true)

func mostrar_selecao(animar) -> void:
	var time = Jogo.SELECOES[Jogo.selecao]
	%NomeSelecao.text = time[0]
	%CorCamisa.color  = time[1] if time[1] != null else CAMISA_ORIGINAL
	%CorDetalhe.color = time[2] if time[2] != null else DETALHE_ORIGINAL
	Jogo.vestir(%Jogador, Jogo.selecao)
	
	if (animar):
		# Pulinho do jogador ao trocar de uniforme
		%Jogador.pivot_offset = %Jogador.size / 2
		var tween = create_tween()
		tween.tween_property(%Jogador, "scale", Vector2(1.15, 1.15), 0.08)
		tween.tween_property(%Jogador, "scale", Vector2.ONE, 0.12)

# ---------- Painéis ----------

func abrir_como_jogar() -> void:
	$PainelComoJogar.visible = true
	%Voltar.grab_focus()

func fechar_como_jogar() -> void:
	$PainelComoJogar.visible = false
	%ComoJogar.grab_focus()

func abrir_opcoes() -> void:
	$PainelOpcoes.visible = true
	%VoltarOpcoes.grab_focus()

func fechar_opcoes() -> void:
	$PainelOpcoes.visible = false
	%Opcoes.grab_focus()
