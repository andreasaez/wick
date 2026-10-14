import CoreGraphics

/// Wick's flame, drawn from code so the icon has no binary assets to audit.
/// Shared by the menu bar item and the app icon generator.
enum Flame {
    /// The full flame outline, fitted to `rect` (origin bottom-left).
    static func outer(in rect: CGRect) -> CGPath {
        let p = Mapper(rect)
        let path = CGMutablePath()
        path.move(to: p(0.50, 0.00))
        path.addCurve(to: p(0.12, 0.38), control1: p(0.26, 0.00), control2: p(0.12, 0.17))
        path.addCurve(to: p(0.36, 0.78), control1: p(0.12, 0.56), control2: p(0.26, 0.66))
        path.addCurve(to: p(0.50, 1.00), control1: p(0.44, 0.87), control2: p(0.50, 0.93))
        path.addCurve(to: p(0.70, 0.60), control1: p(0.54, 0.86), control2: p(0.66, 0.74))
        path.addCurve(to: p(0.80, 0.76), control1: p(0.75, 0.64), control2: p(0.80, 0.70))
        path.addCurve(to: p(0.88, 0.38), control1: p(0.85, 0.66), control2: p(0.88, 0.52))
        path.addCurve(to: p(0.50, 0.00), control1: p(0.88, 0.17), control2: p(0.74, 0.00))
        path.closeSubpath()
        return path
    }

    /// The hot core near the base, fitted to the same `rect` as `outer`.
    static func inner(in rect: CGRect) -> CGPath {
        let p = Mapper(rect)
        let path = CGMutablePath()
        path.move(to: p(0.50, 0.07))
        path.addCurve(to: p(0.30, 0.30), control1: p(0.38, 0.07), control2: p(0.30, 0.16))
        path.addCurve(to: p(0.48, 0.64), control1: p(0.30, 0.45), control2: p(0.44, 0.53))
        path.addCurve(to: p(0.70, 0.30), control1: p(0.55, 0.51), control2: p(0.70, 0.44))
        path.addCurve(to: p(0.50, 0.07), control1: p(0.70, 0.16), control2: p(0.62, 0.07))
        path.closeSubpath()
        return path
    }

    private struct Mapper {
        let rect: CGRect
        init(_ rect: CGRect) { self.rect = rect }
        func callAsFunction(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
    }
}
