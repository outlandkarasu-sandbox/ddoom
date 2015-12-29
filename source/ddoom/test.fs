#version 330 core

in vec3 Position_worldspace;
in vec3 Normal_cameraspace;
in vec3 EyeDirection_cameraspace;
in vec3 LightDirection_cameraspace;

uniform vec3 Diffuse; 
uniform vec3 Ambient;
uniform vec3 LightPosition_worldspace;

out vec3 color;

void main() {
    vec3 lightColor = vec3(1.0f, 1.0f, 1.0f);
    float lightPower = 100.0f;
    float distance = length(LightPosition_worldspace - Position_worldspace);


    vec3 n = normalize(Normal_cameraspace);
    vec3 l = normalize(LightDirection_cameraspace);
    float cosTheta = clamp(dot(n, l), 0,1);

    vec3 ambientColor = Ambient * 0.1f;

    color = ambientColor + Diffuse * lightColor * lightPower * cosTheta / (distance * distance);
}

