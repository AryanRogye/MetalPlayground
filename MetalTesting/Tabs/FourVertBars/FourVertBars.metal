//
//  FourVertBars.metal
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

#include <metal_stdlib>
#include "../headers.metal.h"
using namespace metal;

vertex VertexOut
fourVertBarsVertex(
    const device VertexIn* vertices [[buffer(0)]],
    const device float3* colors   [[buffer(1)]],
    constant FourBarUniform& barInfo [[buffer(2)]],
    uint vid [[vertex_id]],
    uint iid [[instance_id]]
) {
    VertexOut out;
    
    float n = barInfo.number;
    float gap = max(0.0, barInfo.gap);
    const float maxWidth = 2.0;
    
    float maxGap = maxWidth / max(1.0, (n - 1.0));
    gap = min(gap, maxGap - 1e-4);
    
    float usable = 2.0 - gap * (n - 1.0);
    float sliceW = usable / n;
    
    float i = float(iid);
    float leftEdge = -1.0 + i * (sliceW + gap);
    
    float2 pos = vertices[vid].pos;     // pos.x ∈ [-1, 1]
    float x01  = pos.x * 0.5 + 0.5;     // → [0, 1]
    pos.x = leftEdge + x01 * sliceW;    // squeeze + shift into slice i
    
    if (barInfo.shouldAnimate) {
        float speed = 2.0;
        float phase = float(iid) * 0.7;
        float s = 0.25 + 0.75 * (0.5 + 0.5 * sin(barInfo.time * speed + phase)); // 0.25..1.0
        
        // map [-1,1] -> [0,1], scale, then back, so bottom is fixed at -1
        float y01 = (pos.y + 1.0) * 0.5;
        pos.y = -1.0 + (y01 * s) * 2.0;
    }
    
    out.position = float4(pos, 0.0, 1.0);
    out.color = float4(colors[vid], 1.0);
    return out;
}

fragment float4
fourVertBarsFragment(VertexOut in [[stage_in]]) {
    return in.color;
}
