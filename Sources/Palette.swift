import AppKit

/// Maps a battery percentage to a color: green while healthy, amber in the
/// middle, red when it's time to plug in. Colors blend smoothly between stops.
enum Palette {
    private static let stops: [(percent: Double, r: Double, g: Double, b: Double)] = [
        (0,   1.00, 0.18, 0.16), // red
        (10,  1.00, 0.18, 0.16), // red
        (25,  1.00, 0.52, 0.00), // orange
        (45,  1.00, 0.80, 0.00), // amber
        (70,  0.20, 0.78, 0.35), // green
        (100, 0.20, 0.78, 0.35), // green
    ]

    static func color(forPercent percent: Int) -> NSColor {
        let p = Double(min(100, max(0, percent)))
        for (lower, upper) in zip(stops, stops.dropFirst()) where p <= upper.percent {
            let span = upper.percent - lower.percent
            let t = span == 0 ? 0 : (p - lower.percent) / span
            return NSColor(
                srgbRed: lower.r + (upper.r - lower.r) * t,
                green: lower.g + (upper.g - lower.g) * t,
                blue: lower.b + (upper.b - lower.b) * t,
                alpha: 1
            )
        }
        let last = stops[stops.count - 1]
        return NSColor(srgbRed: last.r, green: last.g, blue: last.b, alpha: 1)
    }
}
