import AppKit

/// Tracks which app the user was last working in (not TelePad),
/// and explicitly reactivates it before we inject keystrokes.
///
/// Comparison is done by PID (never nil) rather than bundle ID (nil for
/// SPM binaries) so it works correctly whether launched from Xcode or CLI.
final class FocusTracker {

    static let shared = FocusTracker()

    private var previousApp: NSRunningApplication?
    private let ourPID = ProcessInfo.processInfo.processIdentifier

    private init() {}

    // MARK: – Lifecycle

    func start() {
        // Seed immediately — whatever is frontmost right now (likely Xcode on first run)
        seedFromFrontmost()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func appActivated(_ notification: Notification) {
        guard
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                        as? NSRunningApplication,
            app.processIdentifier != ourPID,   // ignore ourselves
            !app.isTerminated
        else { return }

        previousApp = app
    }

    private func seedFromFrontmost() {
        guard
            let app = NSWorkspace.shared.frontmostApplication,
            app.processIdentifier != ourPID
        else { return }
        previousApp = app
    }

    // MARK: – Target resolution

    /// Returns the app that keyboard events should go to.
    /// Priority:
    ///   1. Current frontmost app, if it's not us
    ///   2. Last recorded previous app
    ///   3. nil (we'll still inject — events go wherever the system routes them)
    func targetApp() -> NSRunningApplication? {
        let frontmost = NSWorkspace.shared.frontmostApplication

        // If something other than us is currently frontmost, use it directly
        if let app = frontmost,
           app.processIdentifier != ourPID,
           !app.isTerminated {
            return app
        }

        // We are somehow frontmost — use the tracked previous app
        return previousApp?.isTerminated == false ? previousApp : nil
    }

    // MARK: – Focus restore + inject

    /// Activates the target app, waits for macOS to complete the focus
    /// transfer, then calls `action` (which injects keystrokes).
    ///
    /// 200ms is conservative but reliable across Terminal, VS Code, Chrome,
    /// and Electron apps. Reduce to 100ms if it feels sluggish.
    func restoreFocusThen(_ action: @escaping () async -> Void) async {
        let target = targetApp()

        if let app = target {
            // Must activate on main thread
            _ = await MainActor.run {
                app.activate(options: .activateIgnoringOtherApps)
            }
            // Give macOS time to: route the HID queue, update the key window,
            // and let the target app's first responder settle
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        }

        await action()
    }
}
