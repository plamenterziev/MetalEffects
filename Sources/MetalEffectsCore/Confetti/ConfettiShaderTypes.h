//
//  ConfettiShaderTypes.h
//  MetalEffects
//
//  Created by Plamen Terziev on 21.04.18.
//  Copyright © 2018 Plamen Terziev. All rights reserved.
//

#ifndef ConfettiShaderTypes_h
#define ConfettiShaderTypes_h

#include <simd/simd.h>

typedef enum ConfettiVertexInputIndex {
    ConfettiVertexInputIndexVertices     = 0,
} ConfettiVertexInputIndex;

typedef struct {
    simd::float3 position;
} ConfettiVertex;

typedef struct {
    simd::float4 color;
    simd::float2 size;
    simd::float3 translation;
    simd::float3 rotation; // yaw, pitch, roll
    float timeOffset;
    float acceleration;
    float initialVelocity;
} PerInstanceUniforms;

typedef struct {
    float t;
    simd::float2 viewSize;
} Uniforms;

#endif /* ConfettiShaderTypes_h */
