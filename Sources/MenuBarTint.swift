import AppKit

/// One click-through, borderless strip per display, laid over the menu bar.
/// The strips never take focus, never receive input and hold no content
/// besides a flat color.
@MainActor
final class MenuBarTint {
    private var windows: [NSWindow] = []
    private var color: NSColor = .clear

    var placement: Placement {
        didSet { rebuild() }
    }

    init(placement: Placement) {
        self.placement = placement
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuild() }
        }
        rebuild()
    }

    func setColor(_ color: NSColor, animated: Bool) {
        self.color = color
        CATransaction.begin()
        CATransaction.setAnimationDuration(animated ? 1.2 : 0)
        for window in windows {
            window.contentView?.layer?.backgroundColor = color.cgColor
        }
        CATransaction.commit()
    }

    private func rebuild() {
        windows.forEach { $0.orderOut(nil) }
        windows = NSScreen.screens.compactMap(makeWindow)
        setColor(color, animated: false)
    }

    private func makeWindow(for screen: NSScreen) -> NSWindow? {
        // The menu bar is the gap between the screen's frame and its visible
        // frame. Zero means it's set to auto-hide, so we stay out of the way.
        let height = screen.frame.maxY - screen.visibleFrame.maxY
        guard height > 0 else { return nil }

        let rect = NSRect(x: screen.frame.minX, y: screen.frame.maxY - height,
                          width: screen.frame.width, height: height)
        let window = TintWindow(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.canHide = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.animationBehavior = .none
        window.level = placement.level
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        let view = NSView(frame: NSRect(origin: .zero, size: rect.size))
        view.wantsLayer = true
        view.autoresizingMask = [.width, .height]
        window.contentView = view

        window.setFrame(rect, display: false)
        window.orderFrontRegardless()
        return window
    }
}

/// macOS normally nudges windows down so they never overlap the menu bar.
/// Overlapping it is the whole point here, so keep the frame as given.
private final class TintWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}
