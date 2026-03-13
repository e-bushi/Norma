//
//  DotGridRipple.metal
//  Norma
//
//  Animated dot grid with expanding ripple waves.
//  Each dot pulses in size and brightness as ripples pass through.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Procedural animated dot grid with sonar-style ripple pulses.
/// - Parameters:
///   - position: Current pixel position
///   - color: Base tint color for the dots
///   - size: View dimensions
///   - time: Continuously incrementing time value
///   - spacing: Distance between dot centers
///   - baseRadius: Resting dot radius
///   - rippleOriginX: Ripple center X (normalized 0-1)
///   - rippleOriginY: Ripple center Y (normalized 0-1)
[[stitchable]] half4 dotGridRipple(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float spacing,
    float baseRadius,
    float rippleOriginX,
    float rippleOriginY
) {
    // Find nearest dot center
    float2 cell = floor(position / spacing);
    float2 dotCenter = (cell + 0.5) * spacing;

    // Distance from this pixel to the nearest dot center
    float distToDot = length(position - dotCenter);

    // Ripple origin in pixel space
    float2 rippleOrigin = float2(rippleOriginX * size.x, rippleOriginY * size.y);

    // Distance from this dot to the ripple origin
    float distToOrigin = length(dotCenter - rippleOrigin);

    // Max distance for normalization (diagonal of the view)
    float maxDist = length(size);

    // Slower, broader ripple waves for a premium, breathing feel
    float rippleSpeed1 = 60.0;
    float rippleSpeed2 = 38.0;
    float rippleSpeed3 = 22.0;
    float rippleWidth = 300.0;

    // Ripple 1 — primary wave
    float wave1Pos = fmod(time * rippleSpeed1, maxDist + rippleWidth);
    float wave1Dist = abs(distToOrigin - wave1Pos);
    float wave1 = 1.0 - smoothstep(0.0, rippleWidth, wave1Dist);
    wave1 = wave1 * wave1;  // Ease-in curve for smoother falloff

    // Ripple 2 — secondary, staggered
    float wave2Pos = fmod(time * rippleSpeed2 + maxDist * 0.4, maxDist + rippleWidth);
    float wave2Dist = abs(distToOrigin - wave2Pos);
    float wave2 = 1.0 - smoothstep(0.0, rippleWidth * 0.75, wave2Dist);
    wave2 = wave2 * wave2 * 0.6;

    // Ripple 3 — tertiary, slow ambient pulse
    float wave3Pos = fmod(time * rippleSpeed3 + maxDist * 0.7, maxDist + rippleWidth * 1.2);
    float wave3Dist = abs(distToOrigin - wave3Pos);
    float wave3 = 1.0 - smoothstep(0.0, rippleWidth * 1.2, wave3Dist);
    wave3 = wave3 * wave3 * 0.35;

    // Combined ripple intensity — layered for organic feel
    float ripple = min(max(wave1, max(wave2, wave3)), 1.0);

    // Dot radius: grows smoothly with ripple
    float radius = baseRadius + ripple * baseRadius * 1.5;

    // Dot opacity: visible at rest, brighter during ripple
    float baseOpacity = 0.18;
    float dotOpacity = baseOpacity + ripple * 0.52;

    // Soft radial vignette — fades gently toward far edges
    float2 normalizedPos = dotCenter / size;
    float2 center = float2(0.5, 0.5);
    float radialDist = length(normalizedPos - center) / 0.85;
    float radialFade = 1.0 - smoothstep(0.5, 1.0, radialDist);

    // High-quality anti-aliased dot with wider smoothstep band
    float aaWidth = max(1.2, radius * 0.4);
    float dot = 1.0 - smoothstep(radius - aaWidth, radius + aaWidth, distToDot);

    // Subtle glow halo around each dot for premium softness
    float glowRadius = radius * 2.8;
    float glow = 1.0 - smoothstep(radius, glowRadius, distToDot);
    glow = glow * glow * 0.08;

    // Final alpha: crisp dot + soft glow
    float alpha = (dot * dotOpacity + glow) * radialFade;

    return half4(color.rgb * half(alpha), half(alpha));
}
