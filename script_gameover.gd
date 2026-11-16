extends Control

# Tela de Game Over: aparece quando as vidas acabam

func _ready() -> void:
	Jogo.tocar_musica("gameover")
	%Fase.text   = "Eliminado na fase: %s" % Jogo.nome_fase_perdida
	%Pontos.text = "Pontuação: %d" % Jogo.pontos
	Jogo.vestir(%Jogador, Jogo.selecao)
	%TentarDeNovo.pressed.connect(Jogo.tentar_de_novo)
	%Menu.pressed.connect(Jogo.voltar_ao_menu)
	%TentarDeNovo.grab_focus()
	
	# Título "batendo" na tela
	await get_tree().process_frame # espera o layout calcular o tamanho
	%Titulo.pivot_offset = %Titulo.size / 2
	%Titulo.scale = Vector2(1.8, 1.8)
	%Titulo.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(%Titulo, "modulate:a", 1.0, 0.4)
	tween.tween_property(%Titulo, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
