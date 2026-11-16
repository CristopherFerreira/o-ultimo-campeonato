# O Último Campeonato

Jogo de plataforma 2D feito na disciplina de Projeto de Sistemas Interativos (UNINOVE, 2026).

Leve sua seleção até a taça da Copa do Mundo! Escolha seu uniforme e atravesse seis fases, da várzea ao estádio, enfrentando árbitros que distribuem cartões, bandeirinhas que marcam impedimento, goleiros, o VAR e torcedores rivais. Na grande final, derrote o chefão "Cartão Vermelho" e atravesse os portões do estádio para ser campeão.

## Controles

| Tecla | Ação |
|---|---|
| A / D ou setas | Andar |
| W ou seta para cima | Pular |
| C | Chutar a bola |
| Espaço | Carrinho |
| Shift + Espaço | Cabeçada |
| F | Super chute (com o medidor da torcida cheio) |
| ESC | Pausar |

## Fases

| Fase | Cenário | Desafio |
|---|---|---|
| Fase de grupos | Várzea | Coletar 5 figurinhas |
| Oitavas de final | Praia | Derrotar 5 adversários |
| Quartas de final | Neve | Chegar ao gol em até 60 segundos |
| Semifinal | Cidade | Coletar 6 figurinhas |
| A caminho do estádio | Obra | Derrotar 8 adversários |
| A grande final | Estádio | Derrotar o chefão e atravessar o portão |

## Como abrir o projeto

1. Instale o [Godot Engine 4.7](https://godotengine.org/).
2. No Godot, clique em **Importar** e selecione o arquivo `project.godot` desta pasta.
3. Aperte **F5** para jogar.

A cena inicial é `cena_menu.tscn`. O progresso entre as fases fica no autoload `Jogo` (`script_jogo.gd`).

## Exportação

O projeto tem dois presets em `export_presets.cfg`:

- **Web**: versão para jogar no navegador (itch.io).
- **Windows**: executável único com o jogo embutido.
