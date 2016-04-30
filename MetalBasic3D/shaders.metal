/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 lighting shader for Basic Metal 3D
 */

#include <metal_stdlib>
#include <simd/simd.h>
#include "AAPLSharedTypes.h"

using namespace metal;


fragment vec<float, 4> solidTriangleFragment_Red()
{
    return float4(1.0f, 0.0f, 0.0f, 1.0f);
}

fragment vec<float, 4> solidTriangleFragment_Blue()
{
    return float4(0.0f, 0.0f, 1.0f, 1.0f);
}

vertex float4 solidTriangleVertex_cBuffer(constant float4 *pos_data [[ buffer(0) ]], uint vid [[vertex_id]])
{
    return pos_data[vid];
}

struct VertexInput {
    float4     position [[attribute(0)]];
};

vertex float4 solidTriangleVertex_vFetch(VertexInput in [[stage_in]])
{
    return in.position;
}

