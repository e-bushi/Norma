//
//  NormaDither.metal
//  Norma
//
//  Animated 8x8 Bayer dither over a 2D simplex noise field.
//  Mirrors @paper-design/shaders-react <Dithering /> with parameters tuned
//  to match the O1 landing artboard: shape=simplex, type=8x8, size=1.9,
//  scale=0.51, speed=1.54, lavender on transparent.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Simplex 2D noise (Stefan Gustavson, public domain)

static inline float3 mod289_3(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static inline float2 mod289_2(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static inline float3 permute_3(float3 x) { return mod289_3(((x * 34.0) + 1.0) * x); }

float snoise(float2 v) {
    const float4 C = float4(0.211324865405187,
                            0.366025403784439,
                           -0.577350269189626,
                            0.024390243902439);
    float2 i  = floor(v + dot(v, C.yy));
    float2 x0 = v - i + dot(i, C.xx);
    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289_2(i);
    float3 p = permute_3(permute_3(i.y + float3(0.0, i1.y, 1.0))
                                   + i.x + float3(0.0, i1.x, 1.0));
    float3 m = max(0.5 - float3(dot(x0, x0),
                                 dot(x12.xy, x12.xy),
                                 dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    float3 x = 2.0 * fract(p * C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    float3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// MARK: - 8x8 Bayer threshold matrix (values 0..63 → normalized 0..1)

constant int bayer8[64] = {
     0, 32,  8, 40,  2, 34, 10, 42,
    48, 16, 56, 24, 50, 18, 58, 26,
    12, 44,  4, 36, 14, 46,  6, 38,
    60, 28, 52, 20, 62, 30, 54, 22,
     3, 35, 11, 43,  1, 33,  9, 41,
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47,  7, 39, 13, 45,  5, 37,
    63, 31, 55, 23, 61, 29, 53, 21
};

// MARK: - Norma dither shader
//
// Apply via `.colorEffect(ShaderLibrary.normaDither(.float2(w,h), .float(time), .float(intensity)))`
// onto a `Rectangle().fill(Color.white)`. Intensity 0..1 controls overall
// opacity of the lavender dots; transparent pixels fall through to the
// view underneath (typically NormaPalette.canvas).

[[stitchable]] half4 normaDither(
    float2 pos,
    half4 currentColor,
    float2 size,
    float time,
    float intensity
) {
    // Tuned to visually match Paper's <Dithering /> output — chunkier dots,
    // sparser coverage, larger noise blobs than the bare Paper params imply.
    const float speedParam = 0.55;
    const float dotSize    = 2.0;   // points per dither cell — smaller = blobs read more solid
    const float noiseFreq  = 2.6;   // blobs per screen width (was ~7.8)
    // Bias noise downward so only the brightest peaks light dots — gives
    // the sparse "cloud" feel instead of full 50% coverage.
    const float coverage   = 0.55;

    float2 uv = pos / size;
    float2 noisePos = uv * noiseFreq;

    // Two noise layers with elliptical drift in opposite directions.
    // A single linear `time * vec2` drift makes every blob slide in the
    // same direction — looks like a panning camera. Combining two samples
    // whose offsets sweep in orbits of different speed/phase produces
    // motion that morphs in place instead of marching across the field.
    float t = time * speedParam;
    float2 driftA = float2(sin(t * 0.5),  cos(t * 0.4)) * 1.4;
    float2 driftB = float2(cos(t * 0.37), -sin(t * 0.55)) * 1.1;

    float nA = snoise(noisePos + driftA);
    float nB = snoise(noisePos * 1.6 + driftB);
    float n = (nA + nB * 0.7) / 1.7;

    n = (n + 1.0) * 0.5;          // remap [-1,1] → [0,1]
    n = n * coverage;              // bias toward sparser dot coverage

    // 8x8 Bayer threshold by integer dot cell.
    int2 cell = int2(floor(pos / dotSize));
    int cx = ((cell.x % 8) + 8) % 8;
    int cy = ((cell.y % 8) + 8) % 8;
    float threshold = float(bayer8[cy * 8 + cx]) / 64.0;

    if (n > threshold) {
        // #9676D9 lavender
        return half4(0.588h, 0.463h, 0.851h, half(intensity));
    }
    return half4(0.0h, 0.0h, 0.0h, 0.0h);
}
