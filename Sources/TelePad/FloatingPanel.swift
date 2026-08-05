import Cocoa
import SwiftUI

/// A floating, non-activating panel — the core of TelePad.
///
/// "Non-activating" means clicking buttons inside this panel does NOT steal
/// keyboard focus from the user's IDE, terminal, or browser. The active app
/// retains focus, so CGEventPost keystrokes land there, not here.
final class FloatingPanel: NSPanel {

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 248, height: 356),
            styleMask: [
                .nonactivatingPanel,   // ← the key flag
                .titled,
                .closable,
                .miniaturizable,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )

        // Float above all other windows
        self.level = .floating

        // Visible on every Space and over full-screen apps
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Drag anywhere on the panel background
        self.isMovableByWindowBackground = true

        // Hide the default title bar and native window buttons — SwiftUI draws custom controls
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true

        // Transparent so SwiftUI can draw rounded corners with shadow
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.hasShadow = true

        // Re-open if accidentally closed
        self.hidesOnDeactivate = false

        // SwiftUI content
        let content = NSHostingView(rootView:
            ContentView()
                .environmentObject(ShortcutStore.shared)
        )
        content.translatesAutoresizingMaskIntoConstraints = false
        self.contentView = content
    }

    // Never become key — button clicks are mouse events and work fine without it.
    // This prevents the panel from ever hijacking keyboard focus from the target app.
    // The edit sheet (a child NSWindow) has its own canBecomeKey = true by default.
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
