#version 330 core

in vec3 Position_worldspace;
in vec3 Normal_cameraspace;
in vec3 EyeDirection_cameraspace;
in vec3 LightDirection_cameraspace;

uniform vec3 Diffuse; 
uniform vec3 Ambient;
uniform vec3 Specular; 
uniform vec3 LightPosition_worldspace;

out vec3 color;

void main() {
    vec3 lightColor = vec3(1.0, 1.0, 1.0);
    float lightPower = 100.0;
    float distance = length(LightPosition_worldspace - Position_worldspace);


    vec3 n = normalize(Normal_cameraspace);
    vec3 l = normalize(LightDirection_cameraspace);
    float cosTheta = clamp(dot(n, l), 0,1);

    vec3 ambientColor = Ambient * 0.2;

    vec3 e = normalize(EyeDirection_cameraspace);
    vec3 r = reflect(-l, n);
    float cosAlpha = clamp(dot(e, r), 0,1);

    color = ambientColor
        + Diffuse * lightColor * lightPower * cosTheta / (distance * distance)
        + Specular * lightColor * lightPower * pow(cosAlpha, 5) / (distance * distance);
}

