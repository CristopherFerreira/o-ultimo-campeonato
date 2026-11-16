extends VBoxContainer

# Controle de volume: uma barra para cada canal de áudio.
# Usado no menu (OPÇÕES) e no menu de pausa. Os valores ficam salvos.

const CANAIS = [
	["Master",  "GERAL"],
	["Musica",  "MÚSICA"],
	["Efeitos", "EFEITOS"],
]

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	for canal in CANAIS:
		criar_linha(canal[0], canal[1])

func criar_linha(canal, texto) -> void:
	var linha = HBoxContainer.new()
	linha.add_theme_constant_override("separation", 14)
	add_child(linha)
	
	var nome = Label.new()
	nome.text = texto
	nome.custom_minimum_size.x = 120
	linha.add_child(nome)
	
	var barra = HSlider.new()
	barra.min_value = 0.0
	barra.max_value = 1.0
	barra.step = 0.05
	barra.value = Jogo.volumes[canal]
	barra.custom_minimum_size = Vector2(260, 32)
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	estilizar(barra)
	linha.add_child(barra)
	
	var porcentagem = Label.new()
	porcentagem.custom_minimum_size.x = 70
	porcentagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	porcentagem.text = "%d%%" % round(barra.value * 100)
	linha.add_child(porcentagem)
	
	barra.value_changed.connect(func(valor):
		Jogo.definir_volume(canal, valor)
		Jogo.salvar_opcoes()
		porcentagem.text = "%d%%" % round(valor * 100))
	# Ao soltar a barra, toca um som de teste (ouvir como ficou)
	barra.drag_ended.connect(func(_mudou): Jogo.tocar_som("pulo"))

# Barra verde com o "puxador" amarelo, no estilo do jogo
func estilizar(barra) -> void:
	var fundo = StyleBoxFlat.new()
	fundo.bg_color = Color(0, 0, 0, 0.5)
	fundo.set_corner_radius_all(6)
	fundo.content_margin_top = 6
	fundo.content_margin_bottom = 6
	var cheio = StyleBoxFlat.new()
	cheio.bg_color = Color(0.2, 0.75, 0.35)
	cheio.set_corner_radius_all(6)
	barra.add_theme_stylebox_override("slider", fundo)
	barra.add_theme_stylebox_override("grabber_area", cheio)
	barra.add_theme_stylebox_override("grabber_area_highlight", cheio)
