shader_type canvas_item;

// Shader dos personagens:
//  - troca a cor do uniforme (camisa azul e detalhes amarelos do sprite original)
//  - "lampejo" branco quando o personagem leva um golpe

uniform bool trocar_uniforme = false;
uniform vec3 cor_camisa : source_color = vec3(0.1, 0.3, 0.8);
uniform vec3 cor_detalhe : source_color = vec3(1.0, 0.85, 0.1);
uniform float lampejo : hint_range(0.0, 1.0) = 0.0;

vec3 rgb_para_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

void fragment() {
	vec4 cor = texture(TEXTURE, UV);

	if (trocar_uniforme) {
		vec3 hsv = rgb_para_hsv(cor.rgb);
		if (hsv.x > 0.53 && hsv.x < 0.72 && hsv.y > 0.25) {
			// camisa: mantém o sombreado original (claro/escuro) com a cor nova
			vec3 nova = clamp(cor_camisa * (hsv.z / 0.59), 0.0, 1.0);
			cor.rgb = mix(cor.rgb, nova, smoothstep(0.25, 0.45, hsv.y));
		} else if (hsv.x > 0.11 && hsv.x < 0.2 && hsv.y > 0.5 && hsv.z > 0.5) {
			// detalhes (gola, número, meião)
			cor.rgb = clamp(cor_detalhe * (hsv.z / 0.84), 0.0, 1.0);
		}
	}

	cor.rgb = mix(cor.rgb, vec3(1.0), lampejo);
	COLOR = cor;
}
