//
//  MovingBar.metal
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

#include <metal_stdlib>
#include "../headers.metal.h"

using namespace metal;

float sinBetween(float min, float max, float val) {
    float halfRange = (max - min) / 2;
    float t = min + halfRange + sin(val) * halfRange;
    return t;
}

vertex VertexOut
vertexBarShader(
                const device VertexIn* vertices [[buffer(0)]],
                const device float3* colors   [[buffer(1)]],
                constant BarUniform& barInfo [[buffer(2)]],
                uint vid [[vertex_id]]
                ) {
    VertexOut out;
    
    float2 pos = vertices[vid].pos;
    
    if(barInfo.shouldAnimate) {
        float scaleAmount = sinBetween(0.1, 1.0, barInfo.time);
        pos.y = scale(pos.y, -1, scaleAmount);
    }
    
    out.position = float4(pos, 0.0, 1.0);   // expand 2D → 4D
    out.color = float4(
                       colors[vid],
                       1.0);
    
    return out;
}
 // -> Return Feeds into the Fragment Shader as the `in` inside it


fragment float4 fragmentBarShader(VertexOut in [[stage_in]]) {
    return in.color;
}
