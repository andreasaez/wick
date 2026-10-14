import AppKit

enum Intensity: String, CaseIterable {
    case subtle, medium, strong

    var title: String { rawValue.capitalized }

    var alpha: CGFloat {
        switch self {
        case .subtle: 0.25
        case .medium: 0.45
        case .strong: 0.70
        }
    }
}

enum Placement: String, CaseIterable {
    /// Sits just under the menu bar, so text and icons stay crisp. Best on
    /// macOS 26+, where the menu bar itself is transparent.
    case behind
    /// Sits on top of the menu bar as a translucent wash. Works everywhere.
    case over

    var title: String {
        switch self {
        case .behind: "Behind Menu Bar Text"
        case .over: "Over Menu Bar"
        }
    }

    var level: NSWindow.Level {
        switch self {
        case .behind: NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)
        case .over: NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        }
    }

    static var `default`: Placement {
        ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0))
            ? .behind : .over
    }
}

/// Preferences live in the app's own sandbox container and nowhere else.
@MainActor
final class Settings {
    private let defaults = UserDefaults.standard

    var intensity: Intensity {
        get { defaults.string(forKey: "intensity").flatMap(Intensity.init) ?? .medium }
        set { defaults.set(newValue.rawValue, forKey: "intensity") }
    }

    var placement: Placement {
        get { defaults.string(forKey: "placement").flatMap(Placement.init) ?? .default }
        set { defaults.set(newValue.rawValue, forKey: "placement") }
    }

    /// Off by default: a healthy battery leaves the menu bar untouched.
    var showGreenWhenHealthy: Bool {
        get { defaults.bool(forKey: "showGreenWhenHealthy") }
        set { defaults.set(newValue, forKey: "showGreenWhenHealthy") }
    }

    var showWhilePluggedIn: Bool {
        get { defaults.bool(forKey: "showWhilePluggedIn") }
        set { defaults.set(newValue, forKey: "showWhilePluggedIn") }
    }
}
