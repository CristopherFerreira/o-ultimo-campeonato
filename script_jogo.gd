extends Node

# Autoload "Jogo": guarda o progresso do campeonato entre uma cena e outra.
# Pode ser acessado de qualquer script, ex: Jogo.pontos

const FASES = [
	"res://cena_fase1.tscn", # Fase de grupos
	"res://cena_fase2.tscn", # Oitavas de final
	"res://cena_fase3.tscn", # Quartas de final
	"res://cena_fase4.tscn", # Semifinal
	"res://cena_fase5.tscn", # A caminho do estádio (obra) - a mais difícil
	"res://cena_fase6.tscn", # Final
]

const VIDAS_INICIAIS = 3
const VIDAS_MAXIMAS  = 5
const BOLAS_INICIAIS = 8  # munição: cada chute gasta uma bola
const BOLAS_MAXIMAS  = 15

const SONS = ["chute", "pulo", "carrinho", "cabecada","dano", "inimigo", "apito", "marretada",
	"arremesso", "gol", "vitoria", "super", "ola", "furia", "figurinha", "tique"]

# Seleções que o jogador pode escolher no menu: [nome, cor da camisa, cor dos detalhes]
# (a primeira é o uniforme original do desenho, sem troca de cor)
const SELECOES = [
	["CLÁSSICA",  null,                       null],
	["BRASIL",    Color(1.0, 0.85, 0.1),      Color(0.1, 0.6, 0.25)],
	["ARGENTINA", Color(0.55, 0.8, 1.0),      Color(1, 1, 1)],
	["ALEMANHA",  Color(0.95, 0.95, 0.95),    Color(0.12, 0.12, 0.12)],
	["PORTUGAL",  Color(0.8, 0.1, 0.15),      Color(0.1, 0.55, 0.25)],
	["HOLANDA",   Color(1.0, 0.5, 0.05),      Color(0.1, 0.1, 0.3)],
	["FRANÇA",    Color(0.12, 0.2, 0.5),      Color(1, 1, 1)],
]

const EMPOLGACAO_MAXIMA = 100

signal empolgacao_mudou(valor)
const PARTICULA = preload("res://graficos/particula.png")

var fase_atual = 0
var vidas      = VIDAS_INICIAIS
var pontos     = 0
var bolas      = BOLAS_INICIAIS
var nome_fase_perdida = "" # mostrado na tela de game over

var sons = {}
var selecao    = 1 # índice em SELECOES
var empolgacao = 0 # medidor da torcida: cheio = super chute liberado
var som_ambiente : AudioStreamPlayer # torcida / mar / vento / chuva, conforme o lugar
var som_musica   : AudioStreamPlayer
var musica_atual = ""
var tema_atual   = "estadio" # lugar da cena atual (muda o som de fundo)

# ---------- Volume ----------
# Três canais de áudio (buses): "Master" (geral), "Musica" e "Efeitos" (efeitos + ambiente).
# Os valores vão de 0.0 (mudo) a 1.0 e ficam salvos no computador do jogador.
const ARQUIVO_OPCOES = "user://opcoes.cfg"
var volumes = {"Master": 0.8, "Musica": 0.7, "Efeitos": 0.8}

func _ready() -> void:
	# Continua funcionando com o jogo pausado (ex: som do gol durante a comemoração)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	criar_canais_de_audio()
	carregar_opcoes()
	
	for nome in SONS:
		sons[nome] = load("res://sons/%s.wav" % nome)
	
	# Som de fundo do lugar, tocando sem parar
	som_ambiente = AudioStreamPlayer.new()
	som_ambiente.volume_db = -14 # fica por baixo da música
	som_ambiente.bus = "Efeitos"
	som_ambiente.finished.connect(som_ambiente.play)
	add_child(som_ambiente)
	
	som_musica = AudioStreamPlayer.new()
	som_musica.volume_db = -7
	som_musica.bus = "Musica"
	som_musica.finished.connect(som_musica.play) # toca em loop
	add_child(som_musica)
	
	tocar_ambiente()

func criar_canais_de_audio() -> void:
	for nome in ["Musica", "Efeitos"]:
		if (AudioServer.get_bus_index(nome) == -1):
			AudioServer.add_bus()
			var i = AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nome)
			AudioServer.set_bus_send(i, "Master")

func definir_volume(canal, valor) -> void:
	volumes[canal] = clamp(valor, 0.0, 1.0)
	var i = AudioServer.get_bus_index(canal)
	AudioServer.set_bus_volume_db(i, linear_to_db(max(volumes[canal], 0.0001)))
	AudioServer.set_bus_mute(i, volumes[canal] <= 0.001)

func carregar_opcoes() -> void:
	var cfg = ConfigFile.new()
	if (cfg.load(ARQUIVO_OPCOES) == OK):
		for canal in volumes:
			volumes[canal] = cfg.get_value("volume", canal, volumes[canal])
	for canal in volumes:
		definir_volume(canal, volumes[canal])

func salvar_opcoes() -> void:
	var cfg = ConfigFile.new()
	for canal in volumes:
		cfg.set_value("volume", canal, volumes[canal])
	cfg.save(ARQUIVO_OPCOES)

# ---------- Som de fundo e música ----------

# Cada lugar tem seu som de fundo. Chamado pelo cenário (script_fundo) ao abrir a cena.
func definir_ambiente(tema) -> void:
	tema_atual = tema
	tocar_ambiente()

func tocar_ambiente() -> void:
	var arquivo = "res://sons/torcida.wav" # estádio e várzea: torcida
	if (tema_atual in ["praia", "neve", "cidade", "obra"]):
		arquivo = "res://sons/ambiente_%s.wav" % tema_atual
	
	# Só reinicia o som se ele mudou (senão fica "pulando" a cada fase)
	if (som_ambiente.stream == null or som_ambiente.stream.resource_path != arquivo):
		som_ambiente.stream = load(arquivo)
		som_ambiente.play()

# Músicas: "menu" (tela inicial), "fase" (jogando) e "gameover"
func tocar_musica(nome) -> void:
	musica_atual = nome
	var arquivo = "res://sons/musica_%s.wav" % nome
	if (som_musica.stream == null or som_musica.stream.resource_path != arquivo):
		som_musica.stream = load(arquivo)
		som_musica.play()
	elif (not som_musica.playing):
		som_musica.play()

# ---------- Uniformes ----------

# Aplica as cores de uma seleção no material (shader) de um sprite
func vestir(sprite, indice) -> void:
	var time = SELECOES[indice]
	var material = sprite.material
	if (material == null):
		return
	material.set_shader_parameter("trocar_uniforme", time[1] != null)
	if (time[1] != null):
		material.set_shader_parameter("cor_camisa", time[1])
		material.set_shader_parameter("cor_detalhe", time[2])

# Cada fase tem um adversário com uniforme diferente (nunca igual ao do jogador)
func selecao_rival() -> int:
	var rival = 2 + fase_atual
	while (rival % SELECOES.size() == selecao or rival % SELECOES.size() == 0):
		rival += 1
	return rival % SELECOES.size()

# ---------- Torcida ----------

func empolgar(valor) -> void:
	var antes = empolgacao
	empolgacao = clamp(empolgacao + valor, 0, EMPOLGACAO_MAXIMA)
	if (empolgacao != antes):
		empolgacao_mudou.emit(empolgacao)

func super_chute_pronto() -> bool:
	return empolgacao >= EMPOLGACAO_MAXIMA

# ---------- Sons ----------

func tocar_som(nome, volume_db = 0.0) -> void:
	var player = AudioStreamPlayer.new()
	player.stream      = sons[nome]
	player.volume_db   = volume_db
	player.bus         = "Efeitos"
	player.pitch_scale = randf_range(0.93, 1.07) # varia um pouco para não ficar repetitivo
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

# ---------- Efeitos visuais ----------

# Nuvem de poeira/estrelinhas que some sozinha
func poeira(posicao, cor = Color(1, 1, 1, 0.9), quantidade = 14) -> void:
	var p = CPUParticles2D.new()
	p.texture               = PARTICULA
	p.emitting              = false
	p.one_shot              = true
	p.explosiveness         = 0.9
	p.amount                = quantidade
	p.lifetime              = 0.5
	p.spread                = 180
	p.gravity               = Vector2(0, 300)
	p.initial_velocity_min  = 80
	p.initial_velocity_max  = 220
	p.scale_amount_min      = 0.6
	p.scale_amount_max      = 1.4
	p.color                 = cor
	var sumir = Gradient.new()
	sumir.set_color(0, Color(1, 1, 1, 1))
	sumir.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = sumir
	p.process_mode          = Node.PROCESS_MODE_ALWAYS # anima mesmo na pausa do gol
	p.finished.connect(p.queue_free)
	get_tree().current_scene.add_child(p)
	p.global_position = posicao
	p.emitting = true

# Texto (ex: "+100") que sobe e desaparece
func texto_flutuante(posicao, texto, cor = Color(1, 0.9, 0.2)) -> void:
	var label = Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.z_index = 10
	get_tree().current_scene.add_child(label)
	label.global_position = posicao - Vector2(30, 20)

	var tween = label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 70, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)

func tremer_tela(forca = 10.0) -> void:
	var camera = get_viewport().get_camera_2d()
	if (camera == null):
		return
	var tween = camera.create_tween()
	for i in range(5):
		tween.tween_property(camera, "offset", Vector2(randf_range(-forca, forca), randf_range(-forca, forca)), 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)

func novo_jogo() -> void:
	fase_atual = 0
	vidas      = VIDAS_INICIAIS
	pontos     = 0
	bolas      = BOLAS_INICIAIS
	empolgacao = 0
	carregar_fase()

# Tela de game over: guarda onde o jogador parou
func fim_de_jogo(nome_fase) -> void:
	nome_fase_perdida = nome_fase
	get_tree().change_scene_to_file("res://cena_gameover.tscn")

# "Tentar de novo": recomeça a fase em que perdeu, com vidas e bolas cheias
func tentar_de_novo() -> void:
	vidas      = VIDAS_INICIAIS
	pontos     = 0
	bolas      = BOLAS_INICIAIS
	empolgacao = 0
	carregar_fase()

func carregar_fase() -> void:
	get_tree().change_scene_to_file(FASES[fase_atual])

func proxima_fase() -> void:
	fase_atual += 1
	vidas = min(vidas + 1, VIDAS_MAXIMAS) # ganha uma vida a cada fase vencida

	if (fase_atual < FASES.size()):
		carregar_fase()
	else:
		get_tree().change_scene_to_file("res://cena_campeao.tscn")

func voltar_ao_menu() -> void:
	get_tree().change_scene_to_file("res://cena_menu.tscn")
