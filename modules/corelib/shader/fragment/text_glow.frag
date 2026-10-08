// Text glow shader (GLSL 1.20)
uniform sampler2D u_Tex0;
uniform vec4 u_Color;
uniform float u_Opacity;
uniform mat3 u_TextureMatrix;
varying vec2 v_TexCoord;

void main()
{
    vec4 baseColor = texture2D(u_Tex0, v_TexCoord);

    if (baseColor.a > 0.1) {
        vec3 brightColor = min(baseColor.rgb * u_Color.rgb * 1.2, vec3(1.0));
        gl_FragColor = vec4(brightColor, baseColor.a * u_Opacity);
        return;
    }

    vec2 texelSize = vec2(abs(u_TextureMatrix[0][0]), abs(u_TextureMatrix[1][1]));
    float glow = 0.0;
    const int MAX_STEPS = 2;
    float maxDist = float(MAX_STEPS);

    for (int i = 1; i <= MAX_STEPS; ++i) {
        float distance = float(i);
        float weight = (maxDist - distance + 1.0) / maxDist;
        glow += texture2D(u_Tex0, v_TexCoord + vec2(-texelSize.x * distance, 0.0)).a * weight;
        glow += texture2D(u_Tex0, v_TexCoord + vec2(texelSize.x * distance, 0.0)).a * weight;
        glow += texture2D(u_Tex0, v_TexCoord + vec2(0.0, -texelSize.y * distance)).a * weight;
        glow += texture2D(u_Tex0, v_TexCoord + vec2(0.0, texelSize.y * distance)).a * weight;
    }

    glow = min(glow / 4.0, 1.0);

    if (glow > 0.05)
        gl_FragColor = vec4(u_Color.rgb, glow * 0.5 * u_Opacity);
    else
        discard;
}
