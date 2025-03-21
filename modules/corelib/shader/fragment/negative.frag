uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

void main()
{
  vec4 color = texture2D(u_Tex0, v_TexCoord);
  gl_FragColor = vec4(1.0 - color.rgb, color.a); // negative only rgb
}
