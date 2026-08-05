import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var panel: FloatingPanel?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Show in Dock so user can minimize/restore like Google Drive
        NSApp.setActivationPolicy(.regular)

        // Track the previously-active app BEFORE we do anything else,
        // so the very first injection works correctly.
        FocusTracker.shared.start()

        setupMenuBar()
        setupPanel()
        setupHotkeys()

        // Request Accessibility on first launch — shows the system dialog once,
        // then never again. No banner needed in the UI.
        KeyInjector.requestAccessibilityIfNeeded()
    }

    // MARK: – Menu bar icon

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Use a numpad-style SF Symbol
            button.image = NSImage(
                systemSymbolName: "square.grid.3x3.fill",
                accessibilityDescription: "TelePad"
            )
            button.image?.isTemplate = true
            button.action = #selector(togglePanel)
            button.target = self
        }

        // Right-click menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show / Hide", action: #selector(togglePanel), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Reset Shortcuts", action: #selector(resetShortcuts), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit TelePad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    // MARK: – Panel

    private func setupPanel() {
        panel = FloatingPanel()
        // Position: bottom-right of screen, near where a physical numpad would be
        if let screen = NSScreen.main {
            let sw = screen.visibleFrame.width
            let sh = screen.visibleFrame.height
            let pw = panel!.frame.width
            let ph = panel!.frame.height
            panel!.setFrameOrigin(NSPoint(
                x: screen.visibleFrame.origin.x + sw - pw - 24,
                y: screen.visibleFrame.origin.y + sh - ph - 24
            ))
        }
        panel?.orderFront(nil)
    }

    // MARK: – Global hotkeys

    private func setupHotkeys() {
        GlobalHotkeyMonitor.shared.start(
            onShortcut: { index in
                let text = ShortcutStore.shared.shortcuts[index - 1]
                Task { await KeyInjector.inject(text) }
            },
            onBareKey: { index in
                // Passive monitor fires after digit lands — erase it with ⌫ first
                let text = ShortcutStore.shared.shortcuts[index - 1]
                Task { await KeyInjector.inject("\u{08}" + text) }
            },
            onEnter: {
                // Enter naturally goes to CLI; just disarm lock mode
                GlobalHotkeyMonitor.shared.bareKeyMode = false
                NotificationCenter.default.post(name: .telePadLockOff, object: nil)
            },
            onToggleLock: {
                let next = !GlobalHotkeyMonitor.shared.bareKeyMode
                GlobalHotkeyMonitor.shared.bareKeyMode = next
                NotificationCenter.default.post(name: .telePadLockToggle, object: next)
                Task { await KeyInjector.inject("\u{08}") }  // erase stray 0
            }
        )
    }


    @objc private func togglePanel() {
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.orderFront(nil)
        }
    }

    @objc private func resetShortcuts() {
        ShortcutStore.shared.reset()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

extension Notification.Name {
    static let telePadLockOff    = Notification.Name("com.telepad.lockOff")
    static let telePadLockToggle = Notification.Name("com.telepad.lockToggle")
}
