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

enum Tab { case active, done }

struct ContentView: View {
    @ObservedObject var store: QueueStore
    @State private var newText = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var showSettings = false
    @State private var selectedTab: Tab = .active

    private var activeItems: [QueueItem] { store.items.filter { !$0.isUsed } }
    private var usedItems: [QueueItem]   { store.items.filter { $0.isUsed } }

    var body: some View {
        VStack(spacing: 0) {
            header
            separator
            content
                .overlay(alignment: .top) {
                    if showSettings {
                        settings
                    }
                }
                .animation(.easeOut(duration: 0.2), value: showSettings)
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

            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: showSettings ? "xmark" : "gearshape")
                    .font(.system(size: showSettings ? 9 : 10, weight: .medium))
                    .frame(width: 14, height: 14)
                    .foregroundColor(LN.text2)
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: LN.radius)
                            .fill(Color.clear)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: LN.radius))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LN.pad)
        .padding(.vertical, 12)
        .background(LN.bg)
    }

    // MARK: Settings

    private var settings: some View {
        VStack(spacing: 0) {
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
        .overlay(alignment: .bottom) {
            Rectangle().fill(LN.border).frame(height: 1)
        }
        .transition(.opacity)
    }

    // MARK: Tabs

    private var tabBar: some View {
        HStack(spacing: 0) {
            TabButton("Active", count: activeItems.count, isSelected: selectedTab == .active) {
                withAnimation(.easeInOut(duration: 0.2)) { selectedTab = .active }
            }
            TabButton("Done", count: usedItems.count, isSelected: selectedTab == .done) {
                withAnimation(.easeInOut(duration: 0.2)) { selectedTab = .done }
            }
            Spacer()
        }
        .padding(.horizontal, LN.pad)
        .padding(.vertical, 8)
    }

    // MARK: Content

    private var content: some View {
        VStack(spacing: 0) {
            tabBar
            separator

            let items = selectedTab == .active ? activeItems : usedItems
            if items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(items) { item in
                            ItemRow(item: item, store: store, tab: selectedTab)
                                .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: selectedTab == .active ? "tray" : "checkmark.circle")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(LN.text3.opacity(0.5))
            Text(selectedTab == .active ? "No active items" : "No completed items")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(LN.text2)
            Text(selectedTab == .active ? "Press Enter to add your first item" : "Completed items will appear here")
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
                .lineSpacing(6)
                .lineLimit(1...6)
                .shiftEnterSubmit { addItem() }
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
                    .frame(width: 35, height: 35)
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

// MARK: - Tab Button

private struct TabButton: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    init(_ label: String, count: Int, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(0.5)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .medium))
                }
            }
            .foregroundColor(isSelected ? (label == "Done" ? LN.done : LN.text1) : LN.text3)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? LN.hover : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item Row

struct ItemRow: View {
    let item: QueueItem
    @ObservedObject var store: QueueStore
    let tab: Tab
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 0) {
            Text(item.text)
                .font(.system(size: 13))
                .lineSpacing(3)
                .lineLimit(4)
                .foregroundColor(LN.text1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, LN.pad)
        .padding(.vertical, 8)
        .overlay(alignment: .bottomTrailing) {
            let hoverTint = tab == .active ? LN.accent : LN.done
            HStack(spacing: 2) {
                ActionIcon("doc.on.doc", hoverTint: hoverTint) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.text, forType: .string)
                }
                ActionIcon(
                    item.isUsed ? "checkmark.circle.fill" : "circle",
                    tint: item.isUsed ? LN.done : nil,
                    hoverTint: hoverTint
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        store.toggleUsed(item.id)
                    }
                }
                ActionIcon("trash", hoverTint: hoverTint) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        store.remove(item.id)
                    }
                }
            }
            .padding(.trailing, LN.pad)
            .padding(.bottom, 4)
            .allowsHitTesting(isHovering)
            .opacity(isHovering ? 1 : 0)
        }
        .background(
            RoundedRectangle(cornerRadius: LN.radius)
                .fill(isHovering ? LN.hover : Color.clear)
                .padding(.horizontal, 6)
        )
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.15)) { isHovering = h }
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
    let tint: Color?
    let hoverTint: Color
    let action: () -> Void

    init(_ icon: String, tint: Color? = nil, hoverTint: Color = LN.text1, action: @escaping () -> Void) {
        self.icon = icon
        self.tint = tint
        self.hoverTint = hoverTint
        self.action = action
    }

    @State private var isHover = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isHover ? .white : (tint ?? LN.text2))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHover ? hoverTint : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isHover ? 1 : 0.2)
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.1)) { isHover = h }
        }
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

// MARK: - Shift+Enter Submit Helper

private extension View {
    @ViewBuilder
    func shiftEnterSubmit(action: @escaping () -> Void) -> some View {
        if #available(macOS 14.0, *) {
            self.onKeyPress(.return, phases: .down) { press in
                if press.modifiers.contains(.shift) { return .ignored }
                action()
                return .handled
            }
        } else {
            self.onSubmit(action)
        }
    }
}

#Preview {
    ContentView(store: QueueStore())
}
