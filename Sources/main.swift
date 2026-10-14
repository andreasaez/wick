import AppKit
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = Settings()
    private lazy var tint = MenuBarTint(placement: settings.placement)
    private lazy var battery = BatteryMonitor { [weak self] state in
        self?.batteryState = state
        self?.render(animated: true)
    }
    private var statusItem: NSStatusItem?
    private var batteryState: BatteryState?

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item

        battery.start()
    }

    private var currentColor: NSColor? {
        guard let state = batteryState else { return nil }
        return Palette.color(forPercent: state.percent)
    }

    private func render(animated: Bool) {
        let visible = batteryState.map { !$0.isPluggedIn || settings.showWhilePluggedIn } ?? false
        let tintColor = visible ? currentColor?.withAlphaComponent(settings.intensity.alpha) : nil
        tint.setColor(tintColor ?? .clear, animated: animated)
        statusItem?.button?.image = Self.flame(color: currentColor)
        statusItem?.button?.setAccessibilityLabel(batteryState.map { "Wick, battery \($0.percent)%" } ?? "Wick")
    }

    /// The menu bar flame, filled with the battery color. Without a battery
    /// it's an outline that follows the menu bar's light or dark appearance.
    private static func flame(color: NSColor?) -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 18), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.addPath(Flame.outer(in: rect.insetBy(dx: 1.5, dy: 1.5)))
            if let color {
                ctx.setFillColor(color.cgColor)
                ctx.fillPath()
            } else {
                ctx.setStrokeColor(NSColor.black.cgColor)
                ctx.setLineWidth(1.3)
                ctx.setLineJoin(.round)
                ctx.strokePath()
            }
            return true
        }
        image.isTemplate = color == nil
        image.accessibilityDescription = "Wick"
        return image
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let status: String
        if let state = batteryState {
            status = "Battery \(state.percent)%" + (state.isPluggedIn ? " — plugged in" : "")
        } else {
            status = "No battery found"
        }
        menu.addItem(NSMenuItem(title: status, action: nil, keyEquivalent: ""))
        menu.addItem(.separator())

        menu.addItem(submenu("Intensity", Intensity.allCases, selected: settings.intensity, title: \.title,
                             action: #selector(chooseIntensity(_:))))
        menu.addItem(submenu("Placement", Placement.allCases, selected: settings.placement, title: \.title,
                             action: #selector(choosePlacement(_:))))

        let plugged = item("Show While Plugged In", #selector(toggleShowWhilePluggedIn))
        plugged.state = settings.showWhilePluggedIn ? .on : .off
        menu.addItem(plugged)

        // A login item records the app's location, so only offer it once
        // Wick lives in /Applications rather than a build folder.
        let installed = Bundle.main.bundleURL.deletingLastPathComponent().path == "/Applications"
        let login = item(installed ? "Launch at Login" : "Launch at Login (install to /Applications first)",
                         #selector(toggleLaunchAtLogin))
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        if !installed && login.state == .off { login.action = nil }
        menu.addItem(login)

        menu.addItem(.separator())
        menu.addItem(item("Quit Wick", #selector(NSApplication.terminate(_:)), key: "q"))
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = action == #selector(NSApplication.terminate(_:)) ? NSApp : self
        return item
    }

    private func submenu<T: RawRepresentable & Equatable>(
        _ title: String, _ options: [T], selected: T, title optionTitle: KeyPath<T, String>, action: Selector
    ) -> NSMenuItem where T.RawValue == String {
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for option in options {
            let child = item(option[keyPath: optionTitle], action)
            child.representedObject = option.rawValue
            child.state = option == selected ? .on : .off
            sub.addItem(child)
        }
        parent.submenu = sub
        return parent
    }

    @objc private func chooseIntensity(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let value = Intensity(rawValue: raw) else { return }
        settings.intensity = value
        render(animated: true)
    }

    @objc private func choosePlacement(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let value = Placement(rawValue: raw) else { return }
        settings.placement = value
        tint.placement = value
    }

    @objc private func toggleShowWhilePluggedIn() {
        settings.showWhilePluggedIn.toggle()
        render(animated: true)
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            NSSound.beep()
        }
        if service.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
