#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D ImageSampler;

varying vec2 texCoord;

void main() {
    gl_FragColor = texture2D(ImageSampler, vec2(texCoord.x, -texCoord.y));
}
