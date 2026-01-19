//
//  CoinEffects.metal
//  Norma
//
//  Metal shaders for coin animation effects.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Helper Functions

/// Pseudo-random hash function
float coinRandom(float2 st) {
    return fract(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
}

/// Value noise with smooth Hermite interpolation
float coinValueNoise(float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);

    float a = coinRandom(i);
    float b = coinRandom(i + float2(1.0, 0.0));
    float c = coinRandom(i + float2(0.0, 1.0));
    float d = coinRandom(i + float2(1.0, 1.0));

    // Smooth Hermite interpolation (quintic curve)
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    return mix(mix(a, b, u.x),
               mix(c, d, u.x), u.y);
}

// MARK: - Ripple Distortion Effect
// Distorts underlying content with animated ripple waves.
// Used when the coin appears in ChatEmptyStateView.

/// Ripple distortion shader - distorts content with animated waves
/// - Parameters:
///   - pos: Current pixel position
///   - l: Source layer to sample
///   - boundingBox: Bounding rectangle of the view
///   - time: Animation time (0 to 1)
///   - noiseScale: Scale of the noise perturbation
///   - strength: Overall displacement strength
[[stitchable]] half4 coinRipple(
    float2 pos,
    SwiftUI::Layer l,
    float4 boundingBox,
    float time,
    float noiseScale,
    float strength
) {
    float2 size = float2(boundingBox[2], boundingBox[3]);
    float2 uv = pos / size;
    float2 center = float2(0.5, 0.5);

    // Ripple parameters
    float rippleFrequency = 20.0;
    float rippleSpeed = 4.0;
    float noisePerturbation = strength * 1.5;
    float displacementStrength = strength * 0.25;

    // Base noise for organic variation
    float baseNoise = coinValueNoise(uv * noiseScale);

    // Distance from center
    float dist = distance(uv, center);

    // Animated ripple wave
    float rippleWave = sin(
        dist * rippleFrequency
        - time * rippleSpeed
        + baseNoise * noisePerturbation
    );

    // Fade out towards edges and as animation progresses
    float edgeFade = 1.0 - smoothstep(0.3, 0.6, dist);
    float timeFade = 1.0 - smoothstep(0.6, 1.0, time);
    float fade = edgeFade * timeFade;

    // Direction from center for radial displacement
    float2 direction = normalize(uv - center + 1e-5);
    float2 displacement = direction * rippleWave * displacementStrength * fade;
    float2 displacedUv = uv + displacement;

    // Sample the source layer at displaced coordinates
    half4 color = l.sample(displacedUv * size);

    return color;
}

// MARK: - Procedural Ripple Rings (Backup)
// Generates visible ripple rings procedurally without needing source content.

/// Procedural ripple ring generator
[[stitchable]] half4 rippleRings(
    float2 position,
    half4 tintColor,
    float2 size,
    float time,
    float ringCount,
    float ringWidth,
    float maxRadius
) {
    // Center of the effect
    float2 center = size * 0.5;

    // Distance from center
    float distance = length(position - center);

    // Initialize output as transparent
    half4 result = half4(0.0, 0.0, 0.0, 0.0);

    // Generate multiple rings with staggered timing
    for (float i = 0.0; i < ringCount; i++) {
        // Each ring starts slightly later
        float ringDelay = i * 0.08;
        float ringTime = max(0.0, time - ringDelay);

        // This ring's current radius
        float ringRadius = ringTime * maxRadius;

        // Skip if ring hasn't started yet
        if (ringRadius <= 0.0) continue;

        // Distance from this ring's edge
        float ringDist = abs(distance - ringRadius);

        // Ring intensity (sharp falloff at edges)
        float ringIntensity = 1.0 - smoothstep(0.0, ringWidth, ringDist);

        // Fade out as ring expands
        float expansionFade = 1.0 - smoothstep(maxRadius * 0.3, maxRadius, ringRadius);

        // Later rings are slightly dimmer
        float ringBrightness = 1.0 - (i / ringCount) * 0.5;

        // Combined alpha for this ring
        float alpha = ringIntensity * expansionFade * ringBrightness * 0.6;

        // Additive blend with existing result
        result.rgb += tintColor.rgb * half(alpha);
        result.a = max(result.a, half(alpha));
    }

    // Clamp values
    result.rgb = min(result.rgb, half3(1.0));
    result.a = min(result.a, half(0.8));

    return result;
}
