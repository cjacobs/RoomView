import SwiftUI

/// An on-screen movement joystick: drag the knob to set a normalized
/// (strafe, forward) vector, snapping back to zero on release.
struct JoystickView: View {
    @Binding var vector: SIMD2<Float>

    private let radius: CGFloat = 50
    private let knobSize: CGFloat = 44

    @State private var knobOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: knobSize, height: knobSize)
                .offset(knobOffset)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let translation = value.translation
                    let distance = min(radius, (translation.width * translation.width + translation.height * translation.height).squareRoot())
                    let angle = atan2(translation.height, translation.width)
                    let clamped = CGSize(width: cos(angle) * distance, height: sin(angle) * distance)
                    knobOffset = clamped
                    vector = SIMD2<Float>(Float(clamped.width / radius), Float(-clamped.height / radius))
                }
                .onEnded { _ in
                    knobOffset = .zero
                    vector = .zero
                }
        )
    }
}
