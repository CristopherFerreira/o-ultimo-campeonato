extends Control

# Tela final: o jogador derrotou o chefão e atravessou os portões do estádio

func _ready() -> void:
	Jogo.tocar_musica("menu")
	Jogo.tocar_som("gol")
	Jogo.vestir(%Jogador, Jogo.selecao)
	%Pontos.text = "Você atravessou os portões do estádio!\nPontuação final: %d\nSeleção: %s" % [Jogo.pontos, Jogo.SELECOES[Jogo.selecao][0]]
	%VoltarMenu.pressed.connect(Jogo.voltar_ao_menu)
	%VoltarMenu.grab_focus()
