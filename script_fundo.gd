extends CanvasLayer

# Fundo do cenário em camadas. Cada camada anda numa velocidade diferente
# conforme a câmera se move (efeito parallax): o que está longe anda mais devagar.
# Camadas: Ceu -> Estrelas/Nuvens -> Estadio (longe) -> Torcida (perto) -> Base (fundo dos buracos)

@export_enum("estadio", "varzea", "praia", "neve", "cidade", "obra") var tema = "estadio"
@export_enum("nenhum", "neve", "chuva") var clima = "nenhum"
@export var cor_ceu_topo = Color(0.25, 0.55, 0.95)
@export var cor_ceu_base = Color(0.65, 0.85, 1.0)
@export var cor_estadio  = Color(1, 1, 1)   # "tinta" do cenário (escurece à noite)
@export var noite        = false            # mostra estrelas (e acende os refletores no estádio)
@export var ola_automatica = false          # a torcida faz a ola sozinha (menu, tela de campeão)
@export_enum("nenhum", "sol", "lua") var astro = "nenhum"
@export var altura_astro = 0.08             # 0 = topo da tela, 1 = embaixo
@export var vinheta      = true             # escurece um pouco as bordas da tela (fases)

# Cor que aparece no fundo dos buracos de cada lugar
const COR_BASE = {
	"estadio": Color(0.1, 0.1, 0.12),
	"varzea":  Color(0.28, 0.18, 0.1),
	"praia":   Color(0.12, 0.42, 0.6),  # o mar
	"neve":    Color(0.12, 0.16, 0.25),
	"cidade":  Color(0.05, 0.05, 0.08), # a rua lá embaixo
	"obra":    Color(0.2, 0.16, 0.14),
}

const CHAO_MUNDO = 720.0 # limite de baixo da câmera nas fases
const ALTURA_GRAMA = 120.0 # quanto do chão aparece embaixo da tela

var tempo_proxima_ola = 2.0
var balanco = 0.0

func _ready() -> void:
	# Céu em 3 tons: topo -> base -> horizonte mais claro (brilho perto do chão)
	var degrade = Gradient.new()
	degrade.set_color(0, cor_ceu_topo)
	degrade.add_point(0.62, cor_ceu_base)
	degrade.set_color(degrade.get_point_count() - 1, cor_ceu_base.lerp(Color(1, 0.97, 0.88), 0.3 if not noite else 0.08))
	var textura = GradientTexture2D.new()
	textura.gradient = degrade
	textura.fill_to  = Vector2(0, 1) # de cima para baixo
	$Ceu.texture = textura

	carregar_camadas()
	criar_profundidade()

	$Estrelas.visible = noite
	$Nuvens.visible   = not noite and tema != "cidade"
	$NuvensLonge.visible = $Nuvens.visible
	$Luzes.visible    = noite and tema == "estadio"
	# perspectiva: o que está longe fica um pouco "lavado" pela cor do céu
	$Estadio.modulate = cor_estadio.lerp(cor_ceu_base, 0.22 if not noite else 0.12)
	$Torcida.modulate = cor_estadio
	$Base.color       = COR_BASE[tema] * Color(cor_estadio.r, cor_estadio.g, cor_estadio.b)

	criar_astro()
	criar_clima()
	Jogo.definir_ambiente(tema)
	Jogo.empolgacao_mudou.connect(_on_empolgacao_mudou)

func carregar_camadas() -> void:
	if (tema == "estadio"):
		# Estádio: arquibancada com a torcida (com a ola)
		$Torcida.texture = load("res://graficos/fundo_torcida.png")
		$Estadio.texture = load("res://graficos/fundo_estadio.png")
	else:
		$Torcida.texture  = load("res://graficos/%s_perto.png" % tema)
		$Estadio.texture  = load("res://graficos/%s_longe.png" % tema)
		$Torcida.material = null # a ola só existe na arquibancada do estádio

# Camadas extras de profundidade: nuvens distantes (menores e mais lentas) e uma
# neblina leve entre o cenário longe e o perto
func criar_profundidade() -> void:
	var longe = TextureRect.new()
	longe.name = "NuvensLonge"
	longe.texture = $Nuvens.texture
	longe.stretch_mode = TextureRect.STRETCH_TILE
	longe.scale = Vector2(0.6, 0.6)
	longe.modulate = Color(1, 1, 1, 0.55)
	longe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(longe)
	move_child(longe, $Nuvens.get_index())

	var g = Gradient.new()
	var cor = cor_ceu_base.lerp(Color(1, 1, 1), 0.2)
	g.set_color(0, Color(cor, 0))
	g.add_point(0.6, Color(cor, 0.32 if not noite else 0.14))
	g.set_color(g.get_point_count() - 1, Color(cor, 0))
	var tex = GradientTexture2D.new()
	tex.gradient = g
	tex.fill_to = Vector2(0, 1)
	var neblina = TextureRect.new()
	neblina.name = "Neblina"
	neblina.texture = tex
	neblina.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	neblina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(neblina)
	move_child(neblina, $Torcida.get_index())

# Sol ou lua no céu, atrás das nuvens
func criar_astro() -> void:
	if (astro == "nenhum"):
		return
	# brilho em volta do astro
	var g = Gradient.new()
	var cor_brilho = Color(1, 0.95, 0.75) if astro == "sol" else Color(0.75, 0.85, 1)
	g.set_color(0, Color(cor_brilho, 0.45 if astro == "sol" else 0.28))
	g.add_point(0.35, Color(cor_brilho, 0.12))
	g.set_color(g.get_point_count() - 1, Color(cor_brilho, 0))
	var tb = GradientTexture2D.new()
	tb.gradient = g
	tb.fill = GradientTexture2D.FILL_RADIAL
	tb.fill_from = Vector2(0.5, 0.5)
	tb.fill_to = Vector2(1, 0.5)
	var brilho = TextureRect.new()
	brilho.name = "BrilhoAstro"
	brilho.texture = tb
	brilho.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brilho.size = Vector2(620, 620)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(brilho)
	move_child(brilho, $NuvensLonge.get_index())

	var t = TextureRect.new()
	t.name = "Astro"
	t.texture = load("res://graficos/%s.png" % astro)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	move_child(t, $NuvensLonge.get_index()) # fica antes (atrás) das nuvens

# Neve/chuva e a vinheta, na frente de tudo (menos do HUD)
func criar_clima() -> void:
	if (clima == "nenhum" and not vinheta):
		return
	var camada = CanvasLayer.new()
	camada.name  = "CanvasLayer"
	camada.layer = 1
	add_child(camada)

	if (vinheta):
		var degrade = Gradient.new()
		degrade.set_color(0, Color(0, 0, 0, 0))
		degrade.add_point(0.55, Color(0, 0, 0, 0))
		degrade.set_color(degrade.get_point_count() - 1, Color(0, 0, 0, 0.45))
		var textura = GradientTexture2D.new()
		textura.gradient  = degrade
		textura.fill      = GradientTexture2D.FILL_RADIAL
		textura.fill_from = Vector2(0.5, 0.5)
		textura.fill_to   = Vector2(1.1, 1.1)
		var v = TextureRect.new()
		v.name = "Vinheta"
		v.texture = textura
		v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		camada.add_child(v)

	if (clima == "nenhum"):
		return

	var p = CPUParticles2D.new()
	p.name = "Clima"
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	if (clima == "neve"):
		p.texture = Jogo.PARTICULA
		p.amount = 160
		p.lifetime = 9.0
		p.preprocess = 9.0
		p.direction = Vector2(0.2, 1)
		p.spread = 25
		p.gravity = Vector2(0, 15)
		p.initial_velocity_min = 40
		p.initial_velocity_max = 90
		p.scale_amount_min = 0.25
		p.scale_amount_max = 0.7
		p.color = Color(1, 1, 1, 0.9)
	else:
		p.texture = load("res://graficos/gota.png")
		p.amount = 260
		p.lifetime = 1.2
		p.preprocess = 1.2
		p.direction = Vector2(0.12, 1)
		p.spread = 3
		p.gravity = Vector2.ZERO
		p.initial_velocity_min = 700
		p.initial_velocity_max = 900
		p.particle_flag_align_y = true
		p.color = Color(0.75, 0.85, 1, 0.55)
	camada.add_child(p)

# A "ola": uma onda de torcedores levantando atravessa a arquibancada
func fazer_ola() -> void:
	var material = $Torcida.material
	if (material == null):
		return
	var tween = create_tween()
	tween.tween_method(func(x): material.set_shader_parameter("posicao_ola", x), -0.2, 1.2, 1.6)

func _on_empolgacao_mudou(valor) -> void:
	if (Jogo.super_chute_pronto()):
		fazer_ola()
		Jogo.tocar_som("ola")

func _process(delta: float) -> void:
	var tela = get_viewport().get_visible_rect().size
	var camera_x = 0.0
	var subida = 0.0 # quanto a câmera subiu em relação ao chão

	var camera = get_viewport().get_camera_2d()
	if (camera != null):
		var centro = camera.get_screen_center_position()
		camera_x = centro.x
		subida   = CHAO_MUNDO - (centro.y + tela.y / 2)

	$Ceu.size = tela

	# Quanto mais empolgada, mais a torcida balança; cheia, faz a ola de tempos em tempos
	balanco = lerp(balanco, Jogo.empolgacao / float(Jogo.EMPOLGACAO_MAXIMA), 0.05)
	if ($Torcida.material != null):
		$Torcida.material.set_shader_parameter("empolgacao", balanco)
	tempo_proxima_ola -= delta
	if (tempo_proxima_ola <= 0 and (ola_automatica or Jogo.super_chute_pronto())):
		tempo_proxima_ola = 4.0
		fazer_ola()

	var astro_no = get_node_or_null("Astro")
	if (astro_no != null):
		astro_no.position = Vector2(tela.x * 0.6 - camera_x * 0.005 - 128, tela.y * max(altura_astro, 0.16) - 128 + subida * 0.05)
		var brilho_no = get_node_or_null("BrilhoAstro")
		if (brilho_no != null):
			brilho_no.position = astro_no.position + Vector2(128, 128) - brilho_no.size / 2
	var vinheta_no = get_node_or_null("CanvasLayer/Vinheta")
	if (vinheta_no != null):
		vinheta_no.size = tela

	# Neve/chuva cobrindo a tela toda
	var clima_no = get_node_or_null("CanvasLayer/Clima")
	if (clima_no != null):
		clima_no.position = Vector2(tela.x / 2, -30)
		clima_no.emission_rect_extents = Vector2(tela.x * 0.7, 10)

	# Linha do chão na tela quando a câmera está embaixo
	var linha_chao = tela.y - ALTURA_GRAMA
	var topo_torcida = linha_chao + 10 - $Torcida.texture.get_height()

	posicionar($Estrelas, camera_x, subida, 0.02, 0)
	posicionar($Nuvens,   camera_x, subida, 0.1,  tela.y * 0.04, 12)
	var topo_estadio = topo_torcida + 40 - $Estadio.texture.get_height()
	posicionar($Estadio,  camera_x, subida, 0.3,  topo_estadio)
	posicionar($Luzes,    camera_x, subida, 0.3,  topo_estadio)
	posicionar($Torcida,  camera_x, subida, 0.6,  topo_torcida)
	posicionar_nuvens_longe(camera_x, subida, tela)
	# neblina na altura do pé do cenário distante
	var nb = $Neblina
	nb.size = Vector2(tela.x, 150)
	nb.position = Vector2(0, $Estadio.position.y + $Estadio.texture.get_height() - 120)

	$Base.position = Vector2(0, $Torcida.position.y + $Torcida.texture.get_height() - 2)
	$Base.size     = Vector2(tela.x, max(0.0, tela.y - $Base.position.y))

func posicionar_nuvens_longe(camera_x, subida, tela) -> void:
	var c = $NuvensLonge
	var largura = c.texture.get_width()
	var desl = camera_x * 0.05 + Time.get_ticks_msec() / 1000.0 * 5
	c.size = Vector2(tela.x / c.scale.x + largura, c.texture.get_height())
	c.position = Vector2(-fposmod(desl, largura) * c.scale.x, tela.y * 0.14 + subida * 0.05)

# Coloca uma camada repetida (TILE) na tela, deslocada conforme a câmera
func posicionar(camada, camera_x, subida, fator, y, deslize = 0.0) -> void:
	var largura = camada.texture.get_width()
	var tela = get_viewport().get_visible_rect().size
	var deslocamento = camera_x * fator + Time.get_ticks_msec() / 1000.0 * deslize
	camada.size = Vector2(tela.x + largura, camada.texture.get_height())
	if (camada == $Estrelas):
		camada.size.y = tela.y
	camada.position = Vector2(-fposmod(deslocamento, largura), y + subida * fator)
