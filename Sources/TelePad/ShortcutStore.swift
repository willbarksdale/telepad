import Foundation

/// Persists the 9 numpad shortcut labels to UserDefaults.
/// Each shortcut maps numpad key N → a text string injected into the focused app.
final class ShortcutStore: ObservableObject {

    static let shared = ShortcutStore()

    private let storageKey = "shortcuts_v1"

    /// Default shortcuts tuned for agentic AI coding workflows.
    static let defaults: [String] = [
        "plan",      // 1
        "build",     // 2
        "fix",       // 3
        "edit",      // 4
        "explain",   // 5
        "refactor",  // 6
        "test",      // 7
        "review",    // 8
        "continue",  // 9
    ]

    @Published var shortcuts: [String] {
        didSet { save() }
    }

    private init() {
        if let saved = UserDefaults.standard.stringArray(forKey: storageKey),
           saved.count == 9 {
            shortcuts = saved
        } else {
            shortcuts = Self.defaults
        }
    }

    func reset() {
        shortcuts = Self.defaults
    }

    private func save() {
        UserDefaults.standard.set(shortcuts, forKey: storageKey)
    }
}
