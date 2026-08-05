# TelePad — Project Blueprint

> A floating, non-activating macOS numpad utility that injects shortcut text
> directly into any focused app (terminal, IDE, browser, Slack) at the HID level.

---

## Core Concept

Press a numpad button → text appears in whatever app you're using.
No clipboard. No paste. No focus theft. Universal.

```
User types in VS Code / Terminal / Browser
      ↓ (retains focus)
Click numpad key 1
      ↓
"/plan" typed into VS Code by CGEventPost
      ↓
AI agent receives the command
```

---

## Architecture

```
TelePad/
├── Package.swift                  ← SPM manifest, macOS 13+, no sandbox
└── Sources/TelePad/
    ├── main.swift                 ← NSApp entry point
    ├── AppDelegate.swift          ← Lifecycle, menu bar icon (NSStatusItem)
    ├── FloatingPanel.swift        ← NSPanel with .nonactivatingPanel
    ├── ContentView.swift          ← SwiftUI: 3x3 numpad + Enter + edit UI
    ├── KeyInjector.swift          ← CGEventPost engine (the magic)
    └── ShortcutStore.swift        ← UserDefaults persistence for labels
```

---

## Key Technical Decisions

### 1. CGEventPost at HID level

```swift
CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
    ?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &uniChar)
    .post(tap: .cghidEventTap)
```

- `.cghidEventTap` = lowest level, indistinguishable from real keyboard
- Works in every app: Terminal, VS Code, Chrome, Slack, Xcode, etc.
- Unicode API path means any character works (emoji, accents, symbols)
- No keycode lookup table needed — raw Unicode scalar to HID event

**Why not clipboard + Cmd+V?**
Pollutes the clipboard, unreliable with clipboard managers, doesn't work in
password fields or some native inputs.

**Why not Accessibility AXUIElement setTextValue?**
Only works in Accessibility-aware apps, not terminals or browsers.

### 2. NSPanel with .nonactivatingPanel

```swift
NSPanel(
    styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
    ...
)
```

This single flag is the key to the whole system:
- Clicking buttons on the panel does NOT steal focus from the target app
- The previously focused app (VS Code, terminal) retains keyboard focus
- CGEventPost therefore targets that app
- `canBecomeKey = true` so the panel can still receive its own button clicks
- `canBecomeMain = false` to never take over as the main window

### 3. No App Sandbox

SPM-built executables are not sandboxed by default.
CGEventPost to other processes is blocked by the App Sandbox.
This is intentional — we need HID-level access.

> **Note:** If distributed via the Mac App Store, the sandbox restriction means
> CGEventPost will not work. Use direct distribution (.dmg) instead.

### 4. Accessibility Permission

`AXIsProcessTrusted()` must return `true` for CGEventPost to work cross-process.
The user grants this once in:
System Settings → Privacy & Security → Accessibility → [app] ON

The app prompts automatically on first launch and shows a red dot + banner
until permission is granted. Status is polled every 2 seconds.

### 5. Menu bar only (setActivationPolicy .accessory)

No Dock icon. The app lives in the menu bar (numpad icon).
Click the icon to show/hide the floating panel.
The panel defaults to bottom-right, near where a physical numpad would be.

---

## Default Shortcuts

| Key | Default text     | Use case                  |
|-----|-----------------|---------------------------|
| 1   | /plan           | Start a planning session  |
| 2   | /goal           | Set a long-running goal   |
| 3   | implement this  | Trigger implementation    |
| 4   | fix this        | Debugging / error fix     |
| 5   | explain this    | Get an explanation        |
| 6   | continue        | Resume a paused task      |
| 7   | write tests     | Test generation           |
| 8   | refactor this   | Code cleanup              |
| 9   | review this     | Code review               |

All shortcuts are user-editable (right-click any key → Edit shortcut...).
Stored in UserDefaults under key `shortcuts_v1`.

---

## Build & Run

```bash
# Open in Xcode (recommended — handles code signing properly)
open Package.swift

# Or build from CLI
swift build -c release

# Run directly
swift run
```

> **First run:** macOS will prompt for Accessibility permission.
> Go to System Settings → Privacy & Security → Accessibility and enable it.

---

## How to Add Features

### Add a 0 key

1. Extend `ShortcutStore.defaults` to 10 items
2. Change `ForEach(0..<9)` to `0..<10` in ContentView
3. Add a 4th row or full-width 0 key below the Enter key

### Add per-shortcut auto-enter

1. Add `var autoEnter: [Bool]` to `ShortcutStore`
2. In `ContentView.fire(index:)`: if `autoEnter[i]`, append `"\n"` to text
3. Add toggle in `EditShortcutView`

### Add a physical numpad global listener

```swift
NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
    guard event.modifierFlags.contains(.numericPad) else { return }
    // map event.keyCode to shortcut index and fire
}
```

Requires the Accessibility permission already granted by the user.

### Package as .dmg for distribution

```bash
swift build -c release
# Use create-dmg or Platypus to wrap the binary as a .app bundle
```

For a proper .app bundle with icon and Info.plist, generate an Xcode project
with xcodegen from a project.yml spec.

---

## Limitations & Known Issues

| Issue                       | Notes                                                       |
|-----------------------------|-------------------------------------------------------------|
| App Sandbox incompatible    | Cannot ship on Mac App Store; use direct .dmg distribution  |
| CGEventPost 4ms delay       | Needed for Terminal/Vim; can reduce to 2ms for slower apps  |
| SPM binary is not .app      | Run from Xcode for a proper bundle; CLI works for dev       |
| Password/secure fields      | CGEventPost is blocked by design in secure text inputs      |
| Remote Desktop / VMs        | Events target the local system only                         |

---

## Future Roadmap

- [ ] Physical numpad USB HID listener (no clicking required)
- [ ] Per-key color coding
- [ ] Multiple shortcut profiles (switch via menu bar)
- [ ] Global hotkey to show/hide panel (e.g. Cmd+Opt+Space)
- [ ] Haptic feedback via NSHapticFeedbackManager
- [ ] Brief animation on injection showing what was typed
- [ ] iCloud sync of shortcut profiles
- [ ] Proper .app bundle + Sparkle auto-updater for distribution
