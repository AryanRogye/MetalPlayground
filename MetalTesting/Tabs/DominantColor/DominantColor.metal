//
//  DominantColor.metal
//  MetalTesting
//
//  Created by Aryan Rogye on 8/29/25.
//

#include <metal_stdlib>
using namespace metal;

struct Channels {
    float r;
    float g;
    float b;
    float n;
};

struct DebugOut {
    float4 value;   // 16-byte aligned
};

// MARK: - Average Color Kernal
/// Void Because We Write Into the Buffer
kernel void
average_color(
              /// What We Return
              device Channels* out [[buffer(0)]],
              /// Texture We Get in
              texture2d<float, access::read> textureIn [[texture(0)]],
              uint2 gid [[thread_position_in_grid]]
              )
{
    uint width = textureIn.get_width();
    uint height = textureIn.get_height();
    
    if (gid.x >= width || gid.y >= height) {
        return;
    }
    
    float4 color = textureIn.read(gid);
    
    uint index = gid.y * width + gid.x;
    
    out[index].r = color.r;
    out[index].g = color.g;
    out[index].b = color.b;
    out[index].n = 1.0;
}
