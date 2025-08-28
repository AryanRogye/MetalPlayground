//
//  MovingBar.metal
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

#include <metal_stdlib>

using namespace metal;

struct VertexBarIn {
    float2 pos;
};
struct VertexBarOut {
    float4 position [[position]]; // required so rasterizer knows screen pos
    float4 color;                 // any extra varyings you want to interpolate
};

struct BarUniform {
    float time;
    float shouldAnimate;
};

// To scale around a specific baseline b (not the origin), use:
// y' = b + (y - b) * s
float scaleY(float y, float baseline, float scale) {
    return baseline + (y - baseline) * scale;
}

float sinBetween(float min, float max, float val) {
    float halfRange = (max - min) / 2;
    float t = min + halfRange + sin(val) * halfRange;
    return t;
}

vertex VertexBarOut
vertexBarShader(
                const device VertexBarIn* vertices [[buffer(0)]],
                const device float3* colors   [[buffer(1)]],
                constant BarUniform& barInfo [[buffer(2)]],
                uint vid [[vertex_id]]
                ) {
    VertexBarOut out;
    
    float2 pos = vertices[vid].pos;
    
    if(barInfo.shouldAnimate) {
        float scale = sinBetween(0.1, 1.0, barInfo.time);
        pos.y = scaleY(pos.y, -1, scale);
    }
    
    out.position = float4(pos, 0.0, 1.0);   // expand 2D → 4D
    out.color = float4(
                       colors[vid],
                       1.0);
    
    return out;
}
 // -> Return Feeds into the Fragment Shader as the `in` inside it


fragment float4 fragmentBarShader(VertexBarOut in [[stage_in]]) {
    return in.color;
}
