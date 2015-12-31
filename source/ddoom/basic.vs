#version 330 core

layout(location = 0) in vec3 vertexPosition_modelspace;
layout(location = 1) in vec3 vertexNormal_modelspace;
layout(location = 2) in ivec4 boneIDs;
layout(location = 3) in vec4 boneWeights;

uniform mat4 MVP;
uniform mat4 V;
uniform mat4 M;
uniform mat4 MV;
uniform vec3 LightPosition_worldspace;
uniform mat4 Bones[100];

out vec3 Position_worldspace;
out vec3 Normal_cameraspace;
out vec3 EyeDirection_cameraspace;
out vec3 LightDirection_cameraspace;

void main() {
    mat4 boneTransform = mat4(1.0);
/*
    TODO: implements bone deformation.
    mat4 boneTransform = Bones[boneIDs[0]] * boneWeights[0];
    boneTransform += Bones[boneIDs[1]] * boneWeights[1];
    boneTransform += Bones[boneIDs[2]] * boneWeights[2];
    boneTransform += Bones[boneIDs[3]] * boneWeights[3];
*/

    vec4 pos = boneTransform * vec4(vertexPosition_modelspace, 1);
    gl_Position = MVP * pos;

    Position_worldspace = (M * pos).xyz;
    vec3 vertexPosition_cameraspace = (M * V * pos).xyz;
    EyeDirection_cameraspace = vec3(0, 0, 0) - vertexPosition_cameraspace;
    vec3 LightPosition_cameraspace = (V * vec4(LightPosition_worldspace, 1)).xyz;
    LightDirection_cameraspace = LightPosition_cameraspace + EyeDirection_cameraspace;

    Normal_cameraspace = (M * V * boneTransform * vec4(vertexNormal_modelspace, 0)).xyz;
}

