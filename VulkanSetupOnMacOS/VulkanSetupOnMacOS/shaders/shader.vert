//
//  shader.vert
//  VulkanSetupOnMacOS
//
//  Created by Shaobin Tao on 10/12/24.
//

#version 450

layout(binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

// 1 is image

layout(binding = 2) buffer MyStorageBuffer {
    vec4 test;
} ssbo;


layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec2 inTexCoord;

layout(location = 0) out vec3 fragColor;
layout(location = 1) out vec2 fragTexCoord;

void main() {
    gl_Position = ubo.proj * ubo.view * ubo.model * vec4(inPosition, 1.0);
    fragColor = inColor;
    fragTexCoord = inTexCoord;
    
    ssbo.test = vec4(1.1, 2.2, 3.3, 4.4);
    
}

