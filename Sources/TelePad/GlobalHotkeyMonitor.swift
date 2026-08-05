import Cocoa
import Carbon

/// Global keyboard listener for TelePad shortcuts.
///
/// Trigger map (always):
///   ⌃ + number row / numpad → fires onShortcut
///
/// Trigger map (lock mode):
///   bare 1–9 (number row or numpad) → fires onBareKey
///   Enter / Return               → fires onEnter (auto-disarms lock)
final class GlobalHotkeyMonitor {

    static let shared = GlobalHotkeyMonitor()

    var onShortcut:    ((Int) -> Void)?
    var onBareKey:     ((Int) -> Void)?   // bare number while lock is ON
    var onEnter:       (() -> Void)?      // Enter while lock is ON → disarm
    var onToggleLock:  (() -> Void)?      // 0 key → toggle lock on/off

    /// When true, bare 1–9 triggers shortcuts (caller erases the stray digit first).
    var bareKeyMode = false

    private var monitor: Any?
    private init() {}

    // MARK: – Key code tables

    private let numberRow: [UInt16: Int] = [
        18: 1, 19: 2, 20: 3, 21: 4, 23: 5,
        22: 6, 26: 7, 28: 8, 25: 9,
    ]
    private let numpadKeys: [UInt16: Int] = [
        83: 1, 84: 2, 85: 3, 86: 4, 87: 5,
        88: 6, 89: 7, 91: 8, 92: 9,
    ]

    // MARK: – Lifecycle

    func start(
        onShortcut:   @escaping (Int) -> Void,
        onBareKey:    @escaping (Int) -> Void,
        onEnter:      @escaping () -> Void,
        onToggleLock: @escaping () -> Void
    ) {
        self.onShortcut   = onShortcut
        self.onBareKey    = onBareKey
        self.onEnter      = onEnter
        self.onToggleLock = onToggleLock

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }
    }

    func stop() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    // MARK: – Event handling

    private func handle(_ event: NSEvent) {
        let kc    = event.keyCode
        let flags = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .subtracting([.numericPad, .function])

        // ── ⌃ + number row ──────────────────────────────────────────────
        if flags == .control, let idx = numberRow[kc] {
            onShortcut?(idx); return
        }

        // ── ⌃ + numpad 1–9 ──────────────────────────────────────────────
        if flags == .control,
           event.modifierFlags.contains(.numericPad),
           let idx = numpadKeys[kc] {
            onShortcut?(idx); return
        }

        // ── 0 key → toggle lock (numpad 0 = 82, row 0 = 29) ────────────────
        if kc == 82 || kc == 29 {
            onToggleLock?(); return
        }

        // ── Lock mode: bare number row ───────────────────────────────────
        // Passive monitor fires AFTER the digit lands — caller injects ⌫ first.
        if bareKeyMode, flags.isEmpty, let idx = numberRow[kc] {
            onBareKey?(idx); return
        }

        // ── Lock mode: bare numpad 1–9 ───────────────────────────────────
        if bareKeyMode, flags.isEmpty,
           event.modifierFlags.contains(.numericPad),
           let idx = numpadKeys[kc] {
            onBareKey?(idx); return
        }

        // ── Enter / Return — only in lock mode, to auto-disarm ───────────
        if bareKeyMode, (kc == 36 || kc == 76) {
            onEnter?()
        }
    }
}
