import Cocoa
import Carbon

/// Injects text into whatever app currently holds keyboard focus.
/// Uses CGEventPost at the HID level — same mechanism as Raycast / Keyboard Maestro.
/// Works universally: terminal, IDE, browser, Slack, etc.
///
/// Requirements:
///   - App must NOT be sandboxed (Package.swift has no sandbox by default)
///   - User must grant Accessibility permission once in System Settings
enum KeyInjector {

    // MARK: – Accessibility

    static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts the user to grant Accessibility if not already granted.
    static func requestAccessibilityIfNeeded() {
        guard !isAccessibilityGranted else { return }
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(opts as CFDictionary)
    }

    // MARK: – Injection

    /// Types `text` into the currently focused app character by character.
    /// Call from a Task/async context — it yields between characters.
    static func inject(_ text: String) async {

        for scalar in text.unicodeScalars {
            typeScalar(scalar)
            // Small inter-character delay so fast apps (Terminal, Vim) don't drop events
            try? await Task.sleep(nanoseconds: 4_000_000) // 4 ms
        }
    }

    // MARK: – Internals

    private static func typeScalar(_ scalar: Unicode.Scalar) {
        let value = scalar.value

        // Map control characters to virtual key codes
        switch value {
        case 0x0A, 0x0D: postVKey(kVK_Return);  return
        case 0x09:        postVKey(kVK_Tab);     return
        case 0x1B:        postVKey(kVK_Escape);  return
        case 0x08, 0x7F: postVKey(kVK_Delete);  return
        default: break
        }

        // For all printable chars (including emoji, accented letters, symbols):
        // use the CGEvent Unicode string API — no keycode lookup needed.
        let source = CGEventSource(stateID: .hidSystemState)
        var uniChar = UniChar(value & 0xFFFF)

        if let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
            down.keyboardSetUnicodeString(stringLength: 1, unicodeString: &uniChar)
            down.post(tap: .cghidEventTap)
        }
        if let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
            up.keyboardSetUnicodeString(stringLength: 1, unicodeString: &uniChar)
            up.post(tap: .cghidEventTap)
        }
    }

    private static func postVKey(_ keyCode: Int) {
        let source = CGEventSource(stateID: .hidSystemState)
        let vk = CGKeyCode(keyCode)
        CGEvent(keyboardEventSource: source, virtualKey: vk, keyDown: true)?.post(tap: .cghidEventTap)
        CGEvent(keyboardEventSource: source, virtualKey: vk, keyDown: false)?.post(tap: .cghidEventTap)
    }
}
