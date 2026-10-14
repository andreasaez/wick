import AppKit

/// Maps a battery percentage to a color: green while healthy, amber in the
/// middle, red when it's time to plug in. Colors blend smoothly between stops.
enum Palette {
    /// At or above this level the battery is healthy (green).
    static let healthy = 70
    /// Fully amber at this level.
    static let warning = 45

    private static let stops: [(percent: Double, r: Double, g: Double, b: Double)] = [
        (0,   1.00, 0.18, 0.16), // red
        (10,  1.00, 0.18, 0.16), // red
        (25,  1.00, 0.52, 0.00), // orange
        (Double(warning), 1.00, 0.80, 0.00), // amber
        (Double(healthy), 0.20, 0.78, 0.35), // green
        (100, 0.20, 0.78, 0.35), // green
    ]

    /// The menu bar tint, or nil to leave the menu bar as macOS draws it.
    /// Unless `showHealthy` is on, a healthy battery shows no tint at all, and
    /// amber fades in as the level drops from `healthy` to `warning`.
    static func tint(forPercent percent: Int, showHealthy: Bool) -> (color: NSColor, strength: Double)? {
        if showHealthy { return (color(forPercent: percent), 1) }
        let strength = min(1, max(0, Double(healthy - percent) / Double(healthy - warning)))
        guard strength > 0 else { return nil }
        return (color(forPercent: min(percent, warning)), strength)
    }

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
