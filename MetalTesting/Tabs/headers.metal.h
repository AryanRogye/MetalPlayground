/// headers.metalh
#pragma once
#include <metal_stdlib>
using namespace metal;

// MARK: - Functions

// get sin between 2 values with a speed modifier
static inline float sinBetweenWithSpeed(float min, float max, float val, float speed) {
    float halfRange = (max - min) / 2;
    float t = min + halfRange + sin(val * speed) * halfRange;
    return t;
}

// To scale around a specific baseline b (not the origin), use:
// val' = b + (val - b) * s
static inline float scale(float val, float baseline, float scale) {
    return baseline + (val - baseline) * scale;
}

// MARK: - Vertex Structs
struct VertexIn {
    float2 pos;
};

struct VertexOut {
    float4 position [[position]]; // required so rasterizer knows screen pos
    float4 color;                 // any extra varyings you want to interpolate
};

// MARK: - Triangle Information
struct TriangleInfo {
    float min;
    float max;
    float time;
    float speed;
};

// MARK: - Bars
struct BarUniform {
    float time;
    float shouldAnimate;
};

struct OptimizedBarUniform {
    float number;
    float time;
    float shouldAnimate;
};

struct FourBarUniform {
    float number;
    float shouldAnimate;
    float time;
    float gap;
};
