// Text golden bold shader (GLSL 1.20)
uniform sampler2D u_Tex0;
uniform vec4 u_Color;
uniform float u_Opacity;
uniform mat3 u_TextureMatrix;
varying vec2 v_TexCoord;

void main()
{
    vec4 baseColor = texture2D(u_Tex0, v_TexCoord);

    if (baseColor.a > 0.1) {
        gl_FragColor = vec4(baseColor.rgb * u_Color.rgb, baseColor.a * u_Opacity);
        return;
    }

    vec2 texelSize = vec2(abs(u_TextureMatrix[0][0]), abs(u_TextureMatrix[1][1]));
    float outline = 0.0;
    float samples = 0.0;

    for (int i = 0; i < 8; ++i) {
        float angle = float(i) * 0.785398;
        vec2 offset = vec2(cos(angle), sin(angle)) * 0.7 * texelSize;
        outline += texture2D(u_Tex0, v_TexCoord + offset).a * 1.5;
        samples += 1.5;
    }

    for (int i = 0; i < 8; ++i) {
        float angle = float(i) * 0.785398;
        vec2 offset = vec2(cos(angle), sin(angle)) * 1.2 * texelSize;
        outline += texture2D(u_Tex0, v_TexCoord + offset).a * 0.8;
        samples += 0.8;
    }

    outline = min(outline / samples, 1.0);

    if (outline > 0.05) {
        vec3 outlineColor = vec3(0.933, 0.518, 0.075);
        float alpha = smoothstep(0.05, 0.4, outline);
        gl_FragColor = vec4(outlineColor, alpha * 0.95 * u_Opacity);
    } else {
        discard;
    }
}
