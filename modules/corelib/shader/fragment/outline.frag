const float offset = 1.0 / 32.0;
uniform float u_Time;
uniform vec4 u_eColor, u_iColor, u_cColor;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

void main()
{
	vec4 col = texture2D(u_Tex0, v_TexCoord);
	if (col.a >= 0.5) {
		float b = texture2D(u_Tex0, vec2(v_TexCoord.x + offset, v_TexCoord.y)).a *
			texture2D(u_Tex0, vec2(v_TexCoord.x, v_TexCoord.y - offset)).a *
			texture2D(u_Tex0, vec2(v_TexCoord.x - offset, v_TexCoord.y)).a *
			texture2D(u_Tex0, vec2(v_TexCoord.x, v_TexCoord.y + offset)).a *
			texture2D(u_Tex0, vec2(v_TexCoord.x + offset, v_TexCoord.y + offset)).a *
			texture2D(u_Tex0, vec2(v_TexCoord.x + offset, v_TexCoord.y - offset)).a *
			texture2D(u_Tex0, vec2(v_TexCoord.x - offset, v_TexCoord.y + offset)).a *
			texture2D(u_Tex0, vec2(v_TexCoord.x - offset, v_TexCoord.y - offset)).a;

		// Internal outline
		if (b == 0.0) {
			gl_FragColor = vec4(u_iColor.rgb, 1.0);

		// Content area
		} else {
			// Has content color
			if (u_cColor.a >= 0.5) {
				gl_FragColor = vec4(mix(col, u_cColor.rgb, 0.5), 1.0);
			} else {
				gl_FragColor = col;
			}
		}
	} else {
		float a = texture2D(u_Tex0, vec2(v_TexCoord.x + offset, v_TexCoord.y)).a +
			texture2D(u_Tex0, vec2(v_TexCoord.x, v_TexCoord.y - offset)).a +
			texture2D(u_Tex0, vec2(v_TexCoord.x - offset, v_TexCoord.y)).a +
			texture2D(u_Tex0, vec2(v_TexCoord.x, v_TexCoord.y + offset)).a;

		// External outline
		if (col.a < 1.0 && a > 0.0) {
			float x = (cos(u_Time * 6.3) + 1.0)/2.0 * 0.2 + 0.8;
			gl_FragColor = vec4(x * u_eColor.rgb, x * u_eColor.a);

		// Outside area
		} else {
			gl_FragColor = col;
		}
	}
}
