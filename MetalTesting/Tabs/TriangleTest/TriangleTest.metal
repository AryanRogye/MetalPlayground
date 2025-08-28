//
//  main.metal
//  MetalTesting
//
//  Created by Aryan Rogye on 8/26/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 pos;
};
struct VertexOut {
    float4 position [[position]]; // required so rasterizer knows screen pos
    float4 color;                 // any extra varyings you want to interpolate
};
struct TriangleInfo {
    float min;
    float max;
    float time;
    float speed;
};

float sinBetween(float min, float max, float val) {
    float halfRange = (max - min) / 2;
    float t = min + halfRange + sin(val) * halfRange;
    return t;
}
float sinBetweenWithSpeed(float min, float max, float val, float speed) {
    float halfRange = (max - min) / 2;
    float t = min + halfRange + sin(val * speed) * halfRange;
    return t;
}

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
