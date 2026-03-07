//
//  SpendingPaceCloud.metal
//  Norma
//
//  Soft radial gradient orb that reflects spending pace through color.
//  Teal = under budget, Purple = on track, Coral/warm = over pace.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Spending Pace Orb Shader

[[stitchable]] half4 spendingPaceCloud(
    float2 pos,
    half4 currentColor,
    float2 size,
    float time,
    float pace
) {
    // Normalize to center, aspect-corrected
    float2 uv = pos / size;
    float2 diff = uv - float2(0.5, 0.5);
    float aspect = size.x / size.y;
    diff.x *= aspect;
    float dist = length(diff);

    // Gentle breathing
    float breathe = 1.0 + 0.03 * sin(time * 0.4);
    dist /= breathe;

    // Clamp pace
    float p = clamp(pace, 0.0, 1.0);

    // Single color per pace — bright center, fades to transparent
    // Under budget: teal
    half3 tealColor  = half3(0.35, 0.75, 0.70);
    // On track: purple
    half3 purpleColor = half3(0.55, 0.40, 0.80);
    // Over budget: warm amber/coral
    half3 warmColor  = half3(0.90, 0.55, 0.30);

    half3 color;
    if (p < 0.5) {
        float t = p * 2.0;
        color = mix(tealColor, purpleColor, half(t));
    } else {
        float t = (p - 0.5) * 2.0;
        color = mix(purpleColor, warmColor, half(t));
    }

    // Single smooth falloff — orb radius stays well inside container
    // Radius ~0.3 means it fades out at ~60% of the half-height
    float alpha = 1.0 - smoothstep(0.0, 0.3, dist);
    alpha = alpha * alpha * alpha; // Cubic falloff for very soft edges

    // Overall intensity
    alpha *= 0.5;

    return half4(color, half(alpha));
}
