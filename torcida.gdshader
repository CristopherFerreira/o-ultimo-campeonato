shader_type canvas_item;

// Faz a torcida pular: a "ola" é uma faixa que atravessa a tela levantando
// os torcedores, e "empolgacao" faz todo mundo balançar um pouco.

uniform float posicao_ola = -1.0;     // 0 = esquerda da tela, 1 = direita
uniform float empolgacao : hint_range(0.0, 1.0) = 0.0;
uniform float limite_torcida = 0.72;  // abaixo disso ficam as placas (não se mexem)

void fragment() {
	vec2 uv = UV;
	float y = fract(uv.y);

	if (y < limite_torcida) {
		float faixa = exp(-pow((SCREEN_UV.x - posicao_ola) * 7.0, 2.0));
		float balanco = empolgacao * (0.5 + 0.5 * sin(TIME * 9.0 + uv.x * 60.0));
		float subir = (faixa * 14.0 + balanco * 3.0) * TEXTURE_PIXEL_SIZE.y;
		// só puxa pixels que também são da torcida (não das placas)
		if (y + subir < limite_torcida) {
			uv.y += subir;
		}
	}
	COLOR = texture(TEXTURE, uv);
}
