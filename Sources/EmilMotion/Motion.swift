// Motion.swift — the house motion tokens every skill in this repo refers to.
// Add the EmilMotion Swift package, or copy this file into your app target (drop the `public`s if you copy). Deployment target: iOS 18, Swift 6.
// The curves are Emil Kowalski's web curves, ported 1:1 via timingCurve.
import SwiftUI

extension Animation {
    /// Strong ease-out for UI that enters, exits, or answers a press. cubic-bezier(0.23, 1, 0.32, 1)
    public static func emilEaseOut(_ duration: TimeInterval = 0.2) -> Animation {
        .timingCurve(0.23, 1, 0.32, 1, duration: duration)
    }
    /// Strong ease-in-out for things already on screen that move or morph. cubic-bezier(0.77, 0, 0.175, 1)
    public static func emilEaseInOut(_ duration: TimeInterval = 0.3) -> Animation {
        .timingCurve(0.77, 0, 0.175, 1, duration: duration)
    }
    /// iOS-like drawer curve (from Ionic). cubic-bezier(0.32, 0.72, 0, 1)
    public static func emilDrawer(_ duration: TimeInterval = 0.5) -> Animation {
        .timingCurve(0.32, 0.72, 0, 1, duration: duration)
    }
    /// CSS `ease`: cubic-bezier(0.25, 0.1, 0.25, 1). Color/highlight changes; Sonner-style toasts at 0.4 s.
    public static func emilEase(_ duration: TimeInterval = 0.2) -> Animation {
        .timingCurve(0.25, 0.1, 0.25, 1, duration: duration)
    }
    /// Press feedback: fast ease-out, 160 ms.
    public static let emilPress = emilEaseOut(0.16)
}

extension Spring {
    /// Default UI spring: critically damped, no overshoot (Apple: damping 1.0, response 0.4).
    public static let emilUI = Spring(response: 0.4, dampingRatio: 1.0)
    /// Momentum spring: only after a flick/throw carried velocity (Apple: damping 0.8).
    public static let emilMomentum = Spring(response: 0.35, dampingRatio: 0.8)
}

/// Pressable feedback for any Button: scale 0.97 on touch-down, 160 ms ease-out.
/// Fires on press, not release, because `isPressed` flips on touch-down.
public struct PressableButtonStyle: ButtonStyle {
    public var scale: CGFloat
    public init(scale: CGFloat = 0.97) { self.scale = scale }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1)
            .animation(.emilPress, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    public static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

/// Apple's momentum projection (Designing Fluid Interfaces, WWDC18).
/// `velocity` in pt/s; 0.998 == UIScrollView.DecelerationRate.normal.
public func project(velocity: CGFloat, decelerationRate: CGFloat = 0.998) -> CGFloat {
    (velocity / 1000) * decelerationRate / (1 - decelerationRate)
}

/// Rubber-band past a boundary: the further past, the less it follows.
public func rubberband(_ overshoot: CGFloat, dimension: CGFloat, constant: CGFloat = 0.55) -> CGFloat {
    (overshoot * dimension * constant) / (dimension + constant * abs(overshoot))
}
