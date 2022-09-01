#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D ImageSampler;

in vec2 texCoord;
out vec4 fragColor;

void main() {
    fragColor = texture(ImageSampler, vec2(texCoord.x, -texCoord.y));
}
