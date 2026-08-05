import SwiftUI

// ─────────────────────────────────────────────
// MARK: – Main numpad view
// ─────────────────────────────────────────────

struct ContentView: View {
    @EnvironmentObject var store: ShortcutStore
    @State private var editingIndex: Int? = nil
    @State private var bareKeyMode = false
    @State private var armedPulse  = false
    @State private var isDarkMode   = true
    @State private var isWindowControlsHovered = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    // Accent colours - Dark Mode
    private let accentA = Color(hue: 0.62, saturation: 0.85, brightness: 1.0)
    private let accentB = Color(hue: 0.74, saturation: 0.80, brightness: 0.95)
    private let armedA  = Color(hue: 0.08, saturation: 0.95, brightness: 1.0)
    private let armedB  = Color(hue: 0.03, saturation: 0.90, brightness: 1.0)

    // Accent colours - Light Mode
    private let lightAccentA = Color(hue: 0.65, saturation: 0.90, brightness: 0.75)
    private let lightAccentB = Color(hue: 0.75, saturation: 0.85, brightness: 0.65)

    private var currentAccentA: Color { isDarkMode ? accentA : lightAccentA }
    private var currentAccentB: Color { isDarkMode ? accentB : lightAccentB }

    var body: some View {
        ZStack {
            // ── Background ───────────────────────────────────────────────
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    isDarkMode
                        ? LinearGradient(
                            colors: [
                                Color(hue: 0.66, saturation: 0.35, brightness: 0.11),
                                Color(hue: 0.72, saturation: 0.30, brightness: 0.07),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [
                                Color(hue: 0.60, saturation: 0.08, brightness: 0.98),
                                Color(hue: 0.65, saturation: 0.14, brightness: 0.92),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          )
                )

            // ── Radial background glow when armed ─────────────────────────
            if bareKeyMode {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [armedA.opacity(armedPulse ? 0.22 : 0.12), .clear],
                            center: .top, startRadius: 0, endRadius: 200
                        )
                    )
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                               value: armedPulse)
            }

            // ── Outer Border ─────────────────────────────────────────────
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    bareKeyMode
                        ? LinearGradient(colors: [armedA.opacity(0.7), armedB.opacity(0.35)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : isDarkMode
                            ? LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.04)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.black.opacity(0.12), Color.black.opacity(0.04)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.2
                )
                .animation(.easeOut(duration: 0.3), value: bareKeyMode)

            VStack(spacing: 0) {
                // Top Titlebar Row with Traffic Lights
                windowTitleBar
                    .padding(.top, 12)
                    .padding(.horizontal, 14)

                // Subheader Row with TelePad Title and Lock Button
                header
                    .padding(.top, 8)
                    .padding(.horizontal, 14)

                // ── 3 × 3 numpad grid ────────────────────────────────────
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<9, id: \.self) { i in
                        NumKeyView(
                            number: i + 1,
                            label: store.shortcuts[i],
                            armed: bareKeyMode,
                            isDarkMode: isDarkMode,
                            accentA: currentAccentA,
                            accentB: currentAccentB,
                            armedA: armedA,
                            onTap: { fire(index: i) },
                            onEdit: { editingIndex = i }
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 256)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onChange(of: bareKeyMode) { armed in
            armedPulse = armed
        }
        .onReceive(NotificationCenter.default.publisher(for: .telePadLockOff)) { _ in
            bareKeyMode = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .telePadLockToggle)) { note in
            if let val = note.object as? Bool { bareKeyMode = val }
        }
        .sheet(isPresented: Binding(
            get: { editingIndex != nil },
            set: { if !$0 { editingIndex = nil } }
        )) {
            if let i = editingIndex {
                EditShortcutView(
                    number: i + 1,
                    text: store.shortcuts[i],
                    isDarkMode: isDarkMode
                ) { newText in
                    store.shortcuts[i] = newText
                    editingIndex = nil
                } onCancel: {
                    editingIndex = nil
                }
            }
        }
    }

    // MARK: – Window TitleBar (Traffic lights + Theme toggle)

    private var windowTitleBar: some View {
        HStack(spacing: 0) {
            // macOS Window Control Buttons (Red, Yellow)
            HStack(spacing: 6) {
                // Red (Close / Hide Panel)
                Button {
                    hidePanel()
                } label: {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.38, blue: 0.35))
                        .frame(width: 11, height: 11)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Color.black.opacity(0.6))
                                .opacity(isWindowControlsHovered ? 1.0 : 0.0)
                        )
                }
                .buttonStyle(.plain)

                // Yellow (Minimize to macOS Dock)
                Button {
                    minimizePanel()
                } label: {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.78, blue: 0.25))
                        .frame(width: 11, height: 11)
                        .overlay(
                            Image(systemName: "minus")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Color.black.opacity(0.6))
                                .opacity(isWindowControlsHovered ? 1.0 : 0.0)
                        )
                }
                .buttonStyle(.plain)
            }
            .onHover { isWindowControlsHovered = $0 }

            Spacer()

            // Dark / Light Mode Toggle Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isDarkMode.toggle()
                }
            } label: {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(isDarkMode ? Color.yellow.opacity(0.85) : Color.indigo.opacity(0.85))
                    .padding(4.5)
                    .background(
                        Circle()
                            .fill(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: – Subheader (Title + Lock Button)

    private var header: some View {
        HStack(spacing: 0) {
            // Brand title
            Text("TelePad")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [currentAccentA, currentAccentB],
                        startPoint: .leading, endPoint: .trailing
                    )
                )

            Spacer()

            // Lock toggle pill — press [0] to arm/disarm
            Button {
                bareKeyMode.toggle()
                GlobalHotkeyMonitor.shared.bareKeyMode = bareKeyMode
            } label: {
                HStack(spacing: 4) {
                    // Key trigger hint badge
                    HStack(spacing: 1) {
                        Text("[")
                            .foregroundStyle(isDarkMode ? Color.white.opacity(0.3) : Color.black.opacity(0.3))
                        Text("0")
                            .foregroundStyle(bareKeyMode ? armedA : (isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.7)))
                        Text("]")
                            .foregroundStyle(isDarkMode ? Color.white.opacity(0.3) : Color.black.opacity(0.3))
                    }
                    .font(.system(size: 9, weight: .bold, design: .monospaced))

                    Image(systemName: bareKeyMode ? "lock.fill" : "lock.open")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(bareKeyMode ? armedA : (isDarkMode ? Color.white.opacity(0.4) : Color.black.opacity(0.4)))
                        .scaleEffect(bareKeyMode ? 1.15 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: bareKeyMode)
                }
                .padding(.horizontal, 7.5)
                .padding(.vertical, 4.5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(bareKeyMode
                              ? armedA.opacity(0.18)
                              : (isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.05)))
                )
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: bareKeyMode)
        }
    }

    // MARK: – Actions

    private func hidePanel() {
        NSApp.terminate(nil)
    }

    private func minimizePanel() {
        for window in NSApp.windows where window is FloatingPanel {
            window.miniaturize(nil)
        }
    }

    private func fire(index: Int) {
        let text = store.shortcuts[index]
        Task {
            await FocusTracker.shared.restoreFocusThen {
                await KeyInjector.inject(text)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: – Individual numpad key
// ─────────────────────────────────────────────

struct NumKeyView: View {
    let number: Int
    let label: String
    let armed: Bool
    let isDarkMode: Bool
    let accentA: Color
    let accentB: Color
    let armedA: Color
    let onTap: () -> Void
    let onEdit: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    private var keyAccent: Color {
        Color(hue: Double(number - 1) / 10.0 + 0.55,
              saturation: isDarkMode ? 0.75 : 0.85, brightness: isDarkMode ? 1.0 : 0.7)
    }

    private var baseFillColor: Color {
        if isPressed {
            return isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.06)
        } else if isHovered {
            return isDarkMode ? Color.white.opacity(0.15) : Color.black.opacity(0.08)
        } else if armed {
            return armedA.opacity(0.06)
        } else {
            return isDarkMode ? Color.white.opacity(0.07) : Color.white.opacity(0.85)
        }
    }

    private var labelColor: Color {
        if armed {
            return Color(hue: 0.08, saturation: 0.85, brightness: isDarkMode ? 1.0 : 0.75)
        } else if isHovered {
            return isDarkMode ? Color.white.opacity(0.95) : Color.black.opacity(0.9)
        } else {
            return isDarkMode ? Color.white.opacity(0.45) : Color.black.opacity(0.5)
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                // Key Number
                Text("\(number)")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        isHovered
                            ? LinearGradient(colors: [accentA, accentB],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.85),
                                                      isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.6)],
                                             startPoint: .top, endPoint: .bottom)
                    )

                // Shortcut Text Label
                Text(label)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(
                ZStack {
                    // Base Fill
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(baseFillColor)

                    // Top Specular Highlight Glass
                    VStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [isDarkMode ? Color.white.opacity(isHovered ? 0.22 : 0.10) : Color.white.opacity(isHovered ? 0.9 : 0.5), .clear],
                                    startPoint: .top, endPoint: .center
                                )
                            )
                            .frame(height: 34)
                        Spacer()
                    }

                    // Border & Armed Outline
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(
                            isHovered
                                ? LinearGradient(colors: [keyAccent.opacity(0.7),
                                                          isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.1)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                                : armed
                                    ? LinearGradient(colors: [armedA.opacity(0.4),
                                                              armedA.opacity(0.15)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [isDarkMode ? Color.white.opacity(0.14) : Color.black.opacity(0.10),
                                                              isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.04)],
                                                     startPoint: .top, endPoint: .bottom),
                            lineWidth: isHovered || armed ? 1.0 : 0.75
                        )
                }
            )
            .shadow(color: isHovered ? keyAccent.opacity(isDarkMode ? 0.3 : 0.2) : (isDarkMode ? .clear : Color.black.opacity(0.05)), radius: 5)
            .scaleEffect(isPressed ? 0.92 : (isHovered ? 1.03 : 1.0))
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .contextMenu {
            Button("Edit shortcut…") { onEdit() }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: – Edit shortcut sheet
// ─────────────────────────────────────────────

struct EditShortcutView: View {
    let number: Int
    @State var text: String
    let isDarkMode: Bool
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Key \(number)")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hue: 0.62, saturation: 0.85, brightness: isDarkMode ? 1.0 : 0.75),
                                 Color(hue: 0.74, saturation: 0.80, brightness: isDarkMode ? 0.95 : 0.65)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("Shortcut text")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField("e.g. /plan", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14, design: .monospaced))
                    .focused($focused)
                    .onSubmit { onSave(text) }
            }

            HStack(spacing: 10) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Save") { onSave(text) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 280)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear { focused = true }
    }
}
