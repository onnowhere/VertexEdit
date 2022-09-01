#version 330

uniform sampler2D DiffuseSampler;

in vec2 inTexCoord;
out vec4 fragColor;

void main() {
    fragColor = texture(DiffuseSampler, inTexCoord);
}
