import SwiftUI
import ServiceManagement

struct ContentView: View {
    @ObservedObject var store: QueueStore
    @State private var newText = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)

                Text("drag.ly")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                if !store.items.isEmpty {
                    Text("\(store.items.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.accentColor.opacity(0.8)))
                }

                Spacer()

                if store.items.contains(where: { $0.isUsed }) {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            store.clearUsed()
                        }
                    } label: {
                        Text("Clear Used")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSettings.toggle()
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundColor(showSettings ? .accentColor : .secondary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)

            // MARK: - Settings Panel
            if showSettings {
                VStack(spacing: 10) {
                    Toggle(isOn: $launchAtLogin) {
                        Label("Launch at Login", systemImage: "arrow.right.circle")
                            .font(.system(size: 12))
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)

                    Divider()

                    HStack {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                store.clearAll()
                            }
                        } label: {
                            Label("Clear All", systemImage: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(store.items.isEmpty ? .secondary : .primary)
                        }
                        .buttonStyle(.plain)
                        .disabled(store.items.isEmpty)

                        Spacer()

                        Button {
                            NSApp.terminate(nil)
                        } label: {
                            Label("Quit", systemImage: "power")
                                .font(.system(size: 11))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()

            // MARK: - Items List
            if store.items.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No items yet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Type below and press Enter")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.items) { item in
                            CardRow(item: item, store: store)
                        }
                    }
                    .padding(14)
                }
            }

            Divider()

            // MARK: - Input (native SwiftUI TextField, no NSTextView)
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Capture your spark...", text: $newText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .lineSpacing(5)
                    .lineLimit(1...8)
                    .onSubmit { addItem() }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )

                Button(action: addItem) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(newText.isEmpty ? .secondary.opacity(0.3) : .accentColor)
                }
                .buttonStyle(.plain)
                .disabled(newText.isEmpty)
            }
            .padding(14)
        }
        .frame(width: 320, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
        .contextMenu {
            Button("Clear Used") {
                store.clearUsed()
            }
            .disabled(!store.items.contains(where: { $0.isUsed }))

            Button("Clear All") {
                store.clearAll()
            }
            .disabled(store.items.isEmpty)

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .onChange(of: launchAtLogin) { newValue in
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = !newValue
            }
        }
    }

    private func addItem() {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.15)) {
            store.add(trimmed)
        }
        newText = ""
    }
}

// MARK: - Card Row

struct CardRow: View {
    let item: QueueItem
    @ObservedObject var store: QueueStore
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.isUsed ? "checkmark.circle.fill" : "grip.vertical")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(item.isUsed ? .green : .secondary.opacity(0.35))
                .frame(width: 12)

            Text(item.text)
                .font(.system(size: 12.5))
                .lineSpacing(3)
                .lineLimit(3)
                .strikethrough(item.isUsed)
                .foregroundColor(item.isUsed ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.text, forType: .string)
                    store.markUsed(item.id)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")

                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        store.remove(item.id)
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
            .opacity(isHovering ? 1 : 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering
                    ? Color(NSColor.controlBackgroundColor)
                    : Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovering ? Color.accentColor.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .opacity(item.isUsed ? 0.5 : 1)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onDrag {
            store.markUsed(item.id)
            return NSItemProvider(object: item.text as NSString)
        }
    }
}

#Preview {
    ContentView(store: QueueStore())
}
