#version 330

in vec4 Position;
out vec2 texCoord;
out vec2 fragCoord;
out vec2 inTexCoord;

uniform mat4 ProjMat;
uniform vec2 InSize;
uniform vec2 OutSize;
uniform vec2 ScreenSize;

void main() {
	vec2 outPos = vec2(-1.0, -1.0);
    if (Position.x > 0.5) outPos.x = 1.0;
    if (Position.y > 0.5) outPos.y = 1.0;
    gl_Position = vec4(outPos.xy, 0.2, 1.0);

    // Coordinate between 0 and 1 based on outtarget buffer size
    texCoord = Position.xy / OutSize;

    // Raw position
    fragCoord = Position.xy;

    // Coordinate between 0 and 1 based on intarget buffer size
    inTexCoord = Position.xy / InSize;
}
