import SwiftUI
import ServiceManagement

// MARK: - Linear-inspired design tokens

private extension Color {
    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(dark) : NSColor(light)
        })
    }
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

private enum LN {
    // Backgrounds
    static let bg        = Color(light: Color(hex: 0xF7F7F7), dark: Color(hex: 0x121212))
    static let elevated  = Color(light: .white,                dark: Color(hex: 0x1B1C1D))
    static let surface   = Color(light: Color(hex: 0xEEEEEE), dark: Color(hex: 0x171717))

    // Text
    static let text1     = Color(light: Color(hex: 0x222326), dark: Color(hex: 0xCCCCCC))
    static let text2     = Color(light: .black.opacity(0.55), dark: .white.opacity(0.55))
    static let text3     = Color(light: .black.opacity(0.35), dark: .white.opacity(0.35))

    // Border & divider
    static let border    = Color(light: .black.opacity(0.08), dark: .white.opacity(0.08))
    static let divider   = Color(light: .black.opacity(0.06), dark: .white.opacity(0.06))

    // Accent (Linear indigo)
    static let accent    = Color(hex: 0x5E6AD2)

    // Status
    static let done      = Color(hex: 0x22C55E)
    static let todo      = Color(light: .black.opacity(0.20), dark: .white.opacity(0.25))

    // Interactive
    static let hover     = Color(light: .black.opacity(0.04), dark: .white.opacity(0.04))

    // Radius & spacing
    static let radius: CGFloat = 6
    static let pad: CGFloat = 14
}

// MARK: - Content View

struct ContentView: View {
    @ObservedObject var store: QueueStore
    @State private var newText = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var showSettings = false

    private var activeItems: [QueueItem] { store.items.filter { !$0.isUsed } }
    private var usedItems: [QueueItem]   { store.items.filter { $0.isUsed } }

    var body: some View {
        VStack(spacing: 0) {
            header
            separator
            content
            separator
            input
        }
        .frame(width: 340, height: 440)
        .background(LN.bg)
        .onChange(of: launchAtLogin) { val in
            do {
                if val { try SMAppService.mainApp.register() }
                else   { try SMAppService.mainApp.unregister() }
            } catch { launchAtLogin = !val }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("drag.ly")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(LN.text1)

                if !store.items.isEmpty {
                    Text("\(store.items.count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(LN.text3)
                }

                Spacer()

                if !usedItems.isEmpty {
                    GhostButton(label: "Clear done", icon: "checkmark.circle") {
                        withAnimation(.easeOut(duration: 0.2)) { store.clearUsed() }
                    }
                }

                GhostButton(
                    label: nil,
                    icon: showSettings ? "xmark" : "gearshape"
                ) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        showSettings.toggle()
                    }
                }
            }
            .padding(.horizontal, LN.pad)
            .padding(.vertical, 12)

            if showSettings {
                settings
            }
        }
    }

    // MARK: Settings

    private var settings: some View {
        VStack(spacing: 0) {
            separator

            // Open at Login
            HStack {
                Label {
                    Text("Open at Login")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(LN.text1)
                } icon: {
                    Image(systemName: "sunrise")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(LN.text3)
                }
                Spacer()
                Toggle("", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }
            .padding(.horizontal, LN.pad)
            .padding(.vertical, 10)

            separator

            // Clear all
            HStack {
                GhostButton(label: "Clear all items", icon: "trash") {
                    withAnimation(.easeOut(duration: 0.2)) { store.clearAll() }
                }
                .disabled(store.items.isEmpty)
                .opacity(store.items.isEmpty ? 0.4 : 1)

                Spacer()

                GhostButton(label: "Quit", icon: "rectangle.portrait.and.arrow.right") {
                    NSApp.terminate(nil)
                }
                .foregroundColor(.red.opacity(0.7))
            }
            .padding(.horizontal, LN.pad)
            .padding(.vertical, 10)
        }
        .background(LN.surface)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: Content

    private var content: some View {
        Group {
            if store.items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Active items
                        if !activeItems.isEmpty {
                            SectionLabel("Active")
                                .padding(.top, 8)
                            ForEach(activeItems) { item in
                                ItemRow(item: item, store: store)
                            }
                        }

                        // Used items
                        if !usedItems.isEmpty {
                            SectionLabel("Done")
                                .padding(.top, activeItems.isEmpty ? 8 : 16)
                            ForEach(usedItems) { item in
                                ItemRow(item: item, store: store)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Circle()
                .strokeBorder(LN.text3.opacity(0.5), lineWidth: 1.5)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(LN.text3)
                )
            Text("No thoughts captured")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(LN.text2)
            Text("Press Enter to add your first item")
                .font(.system(size: 11))
                .foregroundColor(LN.text3)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Input

    private var input: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("New thought...", text: $newText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .lineSpacing(4)
                .lineLimit(1...6)
                .onSubmit { addItem() }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: LN.radius)
                        .fill(LN.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: LN.radius)
                                .stroke(LN.border, lineWidth: 1)
                        )
                )

            Button(action: addItem) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(newText.isEmpty ? LN.text3 : .white)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: LN.radius)
                            .fill(newText.isEmpty ? LN.surface : LN.accent)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LN.radius)
                            .stroke(newText.isEmpty ? LN.border : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(newText.isEmpty)
        }
        .padding(LN.pad)
    }

    // MARK: Helpers

    private var separator: some View {
        Rectangle()
            .fill(LN.divider)
            .frame(height: 1)
    }

    private func addItem() {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            store.add(trimmed)
        }
        newText = ""
    }
}

// MARK: - Section Label

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(LN.text3)
                .kerning(0.5)
            Spacer()
        }
        .padding(.horizontal, LN.pad + 6)
        .padding(.vertical, 6)
    }
}

// MARK: - Item Row (Linear issue-list style)

struct ItemRow: View {
    let item: QueueItem
    @ObservedObject var store: QueueStore
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // Status circle
            Circle()
                .fill(item.isUsed ? LN.done : Color.clear)
                .overlay(
                    Circle().stroke(item.isUsed ? LN.done : LN.todo, lineWidth: 1.5)
                )
                .overlay(
                    item.isUsed
                        ? Image(systemName: "checkmark")
                            .font(.system(size: 6, weight: .black))
                            .foregroundColor(.white)
                        : nil
                )
                .frame(width: 14, height: 14)

            // Text
            Text(item.text)
                .font(.system(size: 13))
                .lineSpacing(3)
                .lineLimit(4)
                .strikethrough(item.isUsed, color: LN.text3)
                .foregroundColor(item.isUsed ? LN.text3 : LN.text1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Actions (hover-reveal)
            if isHovering {
                HStack(spacing: 2) {
                    ActionIcon("doc.on.doc") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(item.text, forType: .string)
                        store.markUsed(item.id)
                    }
                    ActionIcon("trash") {
                        withAnimation(.easeOut(duration: 0.15)) {
                            store.remove(item.id)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, LN.pad)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: LN.radius)
                .fill(isHovering ? LN.hover : Color.clear)
                .padding(.horizontal, 6)
        )
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.1)) { isHovering = h }
        }
        .onDrag {
            store.markUsed(item.id)
            return NSItemProvider(object: item.text as NSString)
        }
    }
}

// MARK: - Action Icon Button

private struct ActionIcon: View {
    let icon: String
    let action: () -> Void

    init(_ icon: String, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }

    @State private var isHover = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isHover ? LN.text1 : LN.text2)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHover ? LN.hover : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHover = $0 }
    }
}

// MARK: - Ghost Button

private struct GhostButton: View {
    let label: String?
    let icon: String
    let action: () -> Void

    @State private var isHover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                if let label {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .foregroundColor(isHover ? LN.text1 : LN.text2)
            .padding(.horizontal, label != nil ? 8 : 6)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: LN.radius)
                    .fill(isHover ? LN.hover : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: LN.radius))
        }
        .buttonStyle(.plain)
        .onHover { isHover = $0 }
    }
}

#Preview {
    ContentView(store: QueueStore())
}
