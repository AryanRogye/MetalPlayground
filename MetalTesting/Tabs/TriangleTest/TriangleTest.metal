//
//  main.metal
//  MetalTesting
//
//  Created by Aryan Rogye on 8/26/25.
//

#include <metal_stdlib>
#include "../headers.metal.h"
using namespace metal;

vertex VertexOut vertexShader(
                              const device VertexIn* vertices [[buffer(0)]],
                              const device float3* colors    [[buffer(1)]],
                              constant TriangleInfo& info     [[buffer(2)]],
                              uint vid [[vertex_id]]) {
    VertexOut out;
    
    float2 xy = vertices[vid].pos;
    out.position = float4(xy, 0.0, 1.0);   // expand 2D → 4D
    
//    float t = sinBetween(0.2, 1.0, time.time);
    float t = sinBetweenWithSpeed(
                                  info.min,
                                  info.max,
                                  info.time,
                                  info.speed);

    out.color = float4(colors[vid] * t, 1.0);
    
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    return in.color;
}
