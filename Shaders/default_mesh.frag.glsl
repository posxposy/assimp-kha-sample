#version 450
in vec2 texCoord;
in float visibility;

layout(location = 0) out vec4 outMain;
layout(location = 1) out vec4 outSecond;

uniform vec4 fogColor;
uniform sampler2D u_texture;

void main()
{
    vec4 texColor = texture(u_texture, texCoord);
    if(texColor.a < 0.6) discard;
    
    outMain =  texColor;//mix(fogColor, texColor, visibility);
    
    outSecond = vec4(0.0, 0.0, 0.0, 1.0);
}