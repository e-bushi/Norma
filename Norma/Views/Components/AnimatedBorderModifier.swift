import SwiftUI

extension Color {
    var components: (red: Double, green: Double, blue: Double) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue))
    }
}

struct AnimatedBorderModifier: ViewModifier {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let useRainbow: Bool
    let isVoiceModeActive: Bool
    @State private var rotation: Double = 0
    @State private var colorShift: Double = 0
    
    init(
        cornerRadius: CGFloat = 20,
        lineWidth: CGFloat = 3,
        useRainbow: Bool = true,
        isVoiceModeActive: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.useRainbow = useRainbow
        self.isVoiceModeActive = isVoiceModeActive
    }
    
    private var rainbowColors: [Color] {
        [
            .red,
            .orange,
            .yellow,
            .green,
            .blue,
            .purple,
            .pink
        ]
    }
    
    private func dynamicRainbowColor(baseHue: Double) -> Color {
        guard useRainbow else { return .purple }
        // Create a color that shifts through the rainbow based on colorShift
        let hue = (baseHue + colorShift).truncatingRemainder(dividingBy: 1.0)
        return Color(hue: hue, saturation: 0.9, brightness: 1.0)
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if isVoiceModeActive {
                        // Traveling light animation when voice mode is ACTIVE
                        // Base border (subtle rainbow or purple)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: useRainbow ? rainbowColors.map { $0.opacity(0.3) } : [Color.purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: lineWidth
                            )
                        
                        // Animated gradient border - using hue rotation for color change
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: .clear, location: 0.35),
                                        .init(color: Color(hue: 0.0, saturation: 0.9, brightness: 1.0).opacity(0.5), location: 0.4),
                                        .init(color: Color(hue: 0.08, saturation: 0.9, brightness: 1.0).opacity(0.7), location: 0.425),
                                        .init(color: Color(hue: 0.16, saturation: 0.9, brightness: 1.0), location: 0.45),
                                        .init(color: Color(hue: 0.33, saturation: 0.9, brightness: 1.0), location: 0.475),
                                        .init(color: Color(hue: 0.5, saturation: 0.9, brightness: 1.0), location: 0.5),
                                        .init(color: Color(hue: 0.66, saturation: 0.9, brightness: 1.0), location: 0.525),
                                        .init(color: Color(hue: 0.83, saturation: 0.9, brightness: 1.0).opacity(0.7), location: 0.55),
                                        .init(color: Color(hue: 0.95, saturation: 0.9, brightness: 1.0).opacity(0.5), location: 0.575),
                                        .init(color: .clear, location: 0.65),
                                        .init(color: .clear, location: 1.0)
                                    ]),
                                    center: .center,
                                    startAngle: .degrees(rotation),
                                    endAngle: .degrees(rotation + 360)
                                ),
                                lineWidth: lineWidth
                            )
                            .hueRotation(.degrees(colorShift * 360))
                            .blur(radius: 1)
                        
                        // Sharp inner border for definition
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: .clear, location: 0.42),
                                        .init(color: Color(hue: 0.16, saturation: 0.9, brightness: 1.0).opacity(0.8), location: 0.475),
                                        .init(color: Color(hue: 0.33, saturation: 0.9, brightness: 1.0).opacity(0.9), location: 0.5),
                                        .init(color: Color(hue: 0.5, saturation: 0.9, brightness: 1.0).opacity(0.8), location: 0.525),
                                        .init(color: .clear, location: 0.58),
                                        .init(color: .clear, location: 1.0)
                                    ]),
                                    center: .center,
                                    startAngle: .degrees(rotation),
                                    endAngle: .degrees(rotation + 360)
                                ),
                                lineWidth: lineWidth * 0.5
                            )
                            .hueRotation(.degrees(colorShift * 360))
                    } else {
                        // Static subtle border when voice mode is inactive
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: lineWidth * 0.5
                            )
                    }
                }
            )
            .onAppear {
                if isVoiceModeActive {
                    startAnimations()
                }
            }
            .onChange(of: isVoiceModeActive) { _, newValue in
                if newValue {
                    // Start animations when voice mode becomes active
                    startAnimations()
                }
            }
    }
    
    private func startAnimations() {
        // Reset the state first to ensure animations restart properly
        rotation = 0
        colorShift = 0
        
        // Small delay to ensure state reset is processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                colorShift = 1.0
            }
        }
    }
}

// Convenience extension
extension View {
    func animatedBorder(
        cornerRadius: CGFloat = 20,
        lineWidth: CGFloat = 3,
        useRainbow: Bool = true,
        isVoiceModeActive: Bool = false
    ) -> some View {
        self.modifier(
            AnimatedBorderModifier(
                cornerRadius: cornerRadius,
                lineWidth: lineWidth,
                useRainbow: useRainbow,
                isVoiceModeActive: isVoiceModeActive
            )
        )
    }
}