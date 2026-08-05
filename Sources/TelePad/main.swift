import AppKit

// Wire up delegate and start the run loop.
// setActivationPolicy is called inside applicationDidFinishLaunching
// after NSApp is fully ready.
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
