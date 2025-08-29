//
//  OptimizedMovingBars.metal
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

#include <metal_stdlib>
#include "../headers.metal.h"

using namespace metal;

vertex VertexOut
vertexOptimizedBarShader(
                const device VertexIn* vertices [[buffer(0)]],
                const device float3* colors   [[buffer(1)]],
                constant OptimizedBarUniform& barInfo [[buffer(2)]],
                uint vid [[vertex_id]],
                uint iid [[instance_id]]
                ) {
    const float barHeight = 2.0;
    VertexOut out;
    
    float number = barInfo.number; /// This is how many peices we wanna split it into
    
    float sliceHeight = barHeight / number;
    float yOffset = float(iid) * sliceHeight;
    
    float2 pos = vertices[vid].pos;
    /// this
    
    pos.x = scale(pos.x, -1.0, 0.2);
    pos.x += yOffset;

    out.position = float4(pos, 0.0, 1.0);   // expand 2D → 4D
    out.color = float4(colors[vid],1.0);
    
    if(barInfo.shouldAnimate) {
        float scaleAmount = sinBetweenWithSpeed(0.1, 1.0, barInfo.time, 1.0);
        pos.y = scale(pos.y, -1, scaleAmount);
    }
    
    return out;
}
// -> Return Feeds into the Fragment Shader as the `in` inside it


fragment float4 fragmentOptimizedBarShader(VertexOut in [[stage_in]]) {
    return in.color;
}
