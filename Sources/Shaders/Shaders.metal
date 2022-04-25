//
//  Shaders.metal
//  MetalEffects
//
//  Created by Plamen Terziev on 17.04.18.
//  Copyright © 2018 Plamen Terziev. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

#import "ConfettiShaderTypes.h"

typedef struct
{
    float4 clipSpacePosition [[position]];
    float4 color;
    float innerRadius;
    float outerRadius;
    float2 uv;
} RasterizerData;

vertex RasterizerData vertexShader(const device ConfettiVertex *vertices [[ buffer(0) ]],
                                   const device PerInstanceUniforms *perInstanceUniforms [[ buffer(1) ]],
                                   constant Uniforms& uniforms [[ buffer(2) ]],
                                   uint vertexID [[ vertex_id ]],
                                   uint instanceID [[ instance_id ]]) {
    
    RasterizerData out;
    
    PerInstanceUniforms instanceUniforms = perInstanceUniforms[instanceID];
    float3 position = vertices[vertexID].position;
    position.xy *= instanceUniforms.size;
    out.uv = position.xy;
    float3 rotation = instanceUniforms.rotation;
    rotation *= uniforms.t;
    
    float cosA;
    float cosB;
    float cosY;
    float sinA = fast::sincos(rotation[0], cosA);
    float sinB = fast::sincos(rotation[1], cosB);
    float sinY = fast::sincos(rotation[2], cosY);
    
    float3x3 rotationMatrix = {
        {cosA * cosB, cosA * sinB * sinY - sinA * cosY, cosA * sinB * cosY + sinA * sinY},
        {sinA * cosB, sinA * sinB * sinY + cosA * cosY, sinA * sinB * cosY - cosA * sinY},
        {-sinB, cosB * sinY, cosB * cosY}
    };

    position *= rotationMatrix;
    position += instanceUniforms.translation;
    float time = max(0.0f, uniforms.t - instanceUniforms.timeOffset);
    float v0 = instanceUniforms.initialVelocity;
    position.y -= (v0 * time + 0.5f * instanceUniforms.acceleration * time * time);
    position.z = 0.5;
    position.xy /= (uniforms.viewSize * 0.5);
    
    out.clipSpacePosition = float4(position, 1);
    out.color = instanceUniforms.color;
    
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]]) {
    return in.color;
}
