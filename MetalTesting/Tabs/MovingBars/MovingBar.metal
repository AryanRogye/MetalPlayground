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

vertex VertexBarOut vertexBarShader(
                                    const device VertexBarIn* vertices [[buffer(0)]],
                                    uint vid [[vertex_id]]) {
    VertexBarOut out;
    
    float2 xy = vertices[vid].pos;
    out.position = float4(xy, 0.0, 1.0);   // expand 2D → 4D
    return out;
} // -> Return Feeds into the Fragment Shader as the `in` inside it

fragment float4 fragmentBarShader(VertexBarOut in [[stage_in]]) {
    return float4(0.0, 1.0, 0.0, 1.0);
}
