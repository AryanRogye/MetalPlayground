//
//  OptimizedMovingBars.metal
//  MetalTesting
//
//  Created by Aryan Rogye on 8/28/25.
//

#include <metal_stdlib>
using namespace metal;

struct OptimizedVertexBarIn {
    float2 pos;
};

struct OptimizedVertexBarOut {
    float4 position [[position]]; // required so rasterizer knows screen pos
    float4 color;                 // any extra varyings you want to interpolate
};

struct OptimizedBarUniform {
    float number;
    float time;
    float shouldAnimate;
};

// To scale around a specific baseline b (not the origin), use:
// y' = b + (y - b) * s
float Oscale(float y, float baseline, float scale) {
    return baseline + (y - baseline) * scale;
}

float OsinBetween(float min, float max, float val) {
    float halfRange = (max - min) / 2;
    float t = min + halfRange + sin(val) * halfRange;
    return t;
}


constant float barHeight = 2.0;

vertex OptimizedVertexBarOut
vertexOptimizedBarShader(
                const device OptimizedVertexBarIn* vertices [[buffer(0)]],
                const device float3* colors   [[buffer(1)]],
                constant OptimizedBarUniform& barInfo [[buffer(2)]],
                uint vid [[vertex_id]],
                uint iid [[instance_id]]
                ) {
    OptimizedVertexBarOut out;
    
    float number = barInfo.number; /// This is how many peices we wanna split it into
    
    float sliceHeight = barHeight / number;
    float yOffset = float(iid) * sliceHeight;
    
    float2 pos = vertices[vid].pos;
    /// this
    
    pos.x = Oscale(pos.x, -1.0, 0.2);
    pos.x += yOffset;

    out.position = float4(pos, 0.0, 1.0);   // expand 2D → 4D
    out.color = float4(
                       colors[vid],
                       1.0);
    
    return out;
}
// -> Return Feeds into the Fragment Shader as the `in` inside it


fragment float4 fragmentOptimizedBarShader(OptimizedVertexBarOut in [[stage_in]]) {
    return in.color;
}
