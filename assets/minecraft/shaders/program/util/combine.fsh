#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D CombineSampler;

uniform vec2 InSize;
uniform vec2 OutSize;

in vec2 fragCoord;
in vec2 texCoord;
out vec4 fragColor;

void main() {
    vec4 src = texture(CombineSampler, texCoord);
    vec4 dst = texture(DiffuseSampler, texCoord);
    fragColor = vec4(src.rgb*src.a + (1-src.a)*dst.rgb, min(src.a + dst.a,1.0));
    if (dst == vec4(0.0) && src != vec4(0.0)) {
        fragColor = vec4(src.rgb, src.a);
    }
}
