extends Node2D

@export var nome_fase           = "FASE DE GRUPOS"
@export var velocidade_inimigos = 150

# ---------- Desafio da fase ----------
# O gol fica trancado (com cadeado) até o desafio ser cumprido.
#   "gol"      -> é só chegar ao gol
#   "coletar"  -> pegar figurinhas (meta = quantas; 0 = todas da fase)
#   "derrotar" -> derrotar "meta" adversários
#   "tempo"    -> chegar ao gol antes de "tempo_limite" segundos
#   "chefao"   -> derrotar o chefão
@export_enum("gol", "coletar", "derrotar", "tempo", "chefao") var objetivo = "gol"
@export var meta         = 0
@export var tempo_limite = 60.0
@export var chao_escorregadio = false # neve: o jogador demora para parar e virar

var jogo_acabou    = false
var progresso      = 0
var tempo_restante = 0.0
var avisou_tempo   = false
var desafio_pronto = false

func _ready() -> void:
	var camera = $Jogador/CharacterBody2D/Camera2D
	camera.limit_left   = -100
	camera.limit_right  = int($ParedeDireita.position.x)
	camera.limit_bottom = 720

	# Quanto mais avançada a fase, mais rápidos os adversários
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		inimigo.velocidade = velocidade_inimigos

	$Jogador/CharacterBody2D.escorregadio = chao_escorregadio

	if (objetivo == "coletar" and meta == 0):
		meta = get_tree().get_nodes_in_group("figurinhas").size()
	tempo_restante = tempo_limite

	desafio_pronto = objetivo_cumprido()
	if (not desafio_pronto):
		$Gol.fechar()

	Jogo.tocar_musica("fase")
	atualizar_hud()
	$HUD.mostrar_mensagem(nome_fase + "\n" + descricao_objetivo(), 3.0)

func _process(delta: float) -> void:
	if (objetivo != "tempo" or jogo_acabou):
		return

	tempo_restante -= delta
	atualizar_objetivo()

	# Últimos 10 segundos: tique-taque
	if (tempo_restante < 10 and int(tempo_restante + delta) != int(tempo_restante)):
		Jogo.tocar_som("tique")
		if (not avisou_tempo):
			avisou_tempo = true
			$HUD.mostrar_mensagem("CORRE! 10 SEGUNDOS!", 1.5)

	if (tempo_restante <= 0):
		tempo_esgotado()

# ---------- Desafio ----------

func descricao_objetivo() -> String:
	match objetivo:
		"coletar":  return "Colete %d figurinhas!" % meta
		"derrotar": return "Derrote %d adversários!" % meta
		"tempo":    return "Chegue ao gol em %d segundos!" % int(tempo_limite)
		"chefao":   return "Derrote o Cartão Vermelho!"
	return "Chegue ao gol!"

func objetivo_cumprido() -> bool:
	match objetivo:
		"coletar", "derrotar":
			return progresso >= meta
		"chefao":
			return get_tree().get_nodes_in_group("chefao").size() == 0
	return true

func texto_objetivo() -> String:
	match objetivo:
		"coletar":  return "FIGURINHAS: %d / %d" % [min(progresso, meta), meta]
		"derrotar": return "ADVERSÁRIOS: %d / %d" % [min(progresso, meta), meta]
		"tempo":    return "TEMPO: %d" % max(0, ceil(tempo_restante))
		"chefao":   return "DERROTE O CHEFÃO" if not objetivo_cumprido() else "VÁ PARA O GOL!"
	return "CHEGUE AO GOL"

func atualizar_objetivo() -> void:
	var cor = Color(0.5, 1, 0.5) if desafio_pronto and objetivo != "tempo" else Color.WHITE
	if (objetivo == "tempo" and tempo_restante < 10):
		cor = Color(1, 0.35, 0.3)
	$HUD.atualizar_objetivo(texto_objetivo(), cor)

# Chamado sempre que algo avança o desafio
func verificar_desafio() -> void:
	atualizar_objetivo()
	if (desafio_pronto or not objetivo_cumprido()):
		return
	desafio_pronto = true
	atualizar_objetivo()
	$Gol.abrir()
	Jogo.tocar_som("vitoria")
	$HUD.mostrar_mensagem("DESAFIO CUMPRIDO!\nVÁ PARA O GOL!", 2.0)

	# Se o jogador já estiver parado dentro do gol, conta na hora
	for corpo in $Gol.get_overlapping_bodies():
		_on_gol_body_entered(corpo)

func coletar_figurinha() -> void:
	adicionar_pontos(50)
	if (objetivo == "coletar"):
		progresso += 1
		verificar_desafio()

func inimigo_derrotado() -> void:
	if (objetivo == "derrotar"):
		progresso += 1
		verificar_desafio()

func tempo_esgotado() -> void:
	Jogo.vidas -= 1
	atualizar_hud()
	Jogo.tocar_som("dano")
	await terminar_fase("TEMPO ESGOTADO!")
	if (Jogo.vidas <= 0):
		Jogo.fim_de_jogo(nome_fase)
	else:
		get_tree().reload_current_scene() # tenta a fase de novo

# ---------- Vidas, pontos e HUD ----------

func perder_vida() -> void:
	if (jogo_acabou):
		return

	Jogo.vidas -= 1
	atualizar_hud()

	if (Jogo.vidas <= 0):
		await terminar_fase("FIM DE JOGO!")
		Jogo.fim_de_jogo(nome_fase)

func adicionar_pontos(valor) -> void:
	Jogo.pontos += valor
	atualizar_hud()

func atualizar_hud() -> void:
	$HUD.atualizar(nome_fase, Jogo.vidas, Jogo.pontos)
	atualizar_objetivo()

func anunciar(texto, duracao = 2.0) -> void:
	$HUD.mostrar_mensagem(texto, duracao)

func chefao_derrotado() -> void:
	$HUD.mostrar_mensagem("CARTÃO VERMELHO\nDERROTADO!", 2.0)
	# O chefão sai do grupo "chefao" nesse momento: confere o desafio
	verificar_desafio()

# ---------- Gol ----------

func _on_gol_body_entered(body: Node2D) -> void:
	if (not body.is_in_group("jogador") or jogo_acabou):
		return

	if (not objetivo_cumprido()):
		$HUD.mostrar_mensagem("GOL TRANCADO!\n" + descricao_objetivo(), 1.5)
		return

	Jogo.tocar_som("gol")
	$Fundo.fazer_ola()
	Jogo.poeira($Gol.global_position + Vector2(60, 0), Color(1, 0.85, 0.2), 40)
	Jogo.poeira($Gol.global_position + Vector2(60, -40), Color(0.3, 0.9, 0.4), 40)
	adicionar_pontos(1000)
	if (objetivo == "tempo"):
		adicionar_pontos(int(tempo_restante) * 10) # bônus pelo tempo que sobrou
	if ($Gol.tipo == "portao"):
		await terminar_fase("PORTÕES ABERTOS!\nVOCÊ CHEGOU AO ESTÁDIO!")
	else:
		await terminar_fase("GOOOOL!")
	Jogo.proxima_fase()

# Mostra a mensagem e congela o jogo por alguns segundos
func terminar_fase(mensagem) -> void:
	jogo_acabou = true
	$HUD.mostrar_mensagem(mensagem)
	get_tree().paused = true

	await get_tree().create_timer(3).timeout
	get_tree().paused = false
