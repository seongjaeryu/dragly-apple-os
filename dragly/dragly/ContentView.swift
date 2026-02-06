import SwiftUI
import ServiceManagement

struct ContentView: View {
    @ObservedObject var store: QueueStore
    @State private var newText = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var showSettings = false
    @State private var inputHeight: CGFloat = 24

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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

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
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
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
                    LazyVStack(spacing: 6) {
                        ForEach(store.items) { item in
                            CardRow(item: item, store: store)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }

            Divider()

            // MARK: - Input
            HStack(alignment: .bottom, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if newText.isEmpty {
                        Text("Type a thought...")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.top, 4)
                            .padding(.leading, 4)
                    }
                    MultilineTextField(text: $newText, dynamicHeight: $inputHeight, onSubmit: addItem)
                        .frame(height: inputHeight)
                }
                .padding(2)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 320, height: 376 + inputHeight)
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
        inputHeight = 24
    }
}

// MARK: - Card Row

struct CardRow: View {
    let item: QueueItem
    @ObservedObject var store: QueueStore
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.isUsed ? "checkmark.circle.fill" : "grip.vertical")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(item.isUsed ? .green : .secondary.opacity(0.4))
                .frame(width: 16)

            Text(item.text)
                .font(.system(size: 12.5))
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
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

// MARK: - Auto-grow NSTextView (suppresses auto-scroll during height adjustment)

private class AutoGrowTextView: NSTextView {
    var suppressScroll = false

    override func scrollRangeToVisible(_ range: NSRange) {
        guard !suppressScroll else { return }
        super.scrollRangeToVisible(range)
    }
}

// MARK: - Multiline TextField (Enter to submit, Shift+Enter for newline)

struct MultilineTextField: NSViewRepresentable {
    @Binding var text: String
    @Binding var dynamicHeight: CGFloat
    var onSubmit: () -> Void

    fileprivate let maxHeight: CGFloat = 200
    fileprivate let minHeight: CGFloat = 24

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()

        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)

        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)

        let textView = AutoGrowTextView(frame: .zero, textContainer: textContainer)
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 13)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 2, height: 2)
        textView.defaultParagraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 4
            return style
        }()
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .legacy
        scrollView.autohidesScrollers = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? AutoGrowTextView else { return }
        if textView.string != text {
            textView.suppressScroll = true
            textView.string = text
            DispatchQueue.main.async {
                context.coordinator.recalcHeight(textView)
                textView.suppressScroll = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MultilineTextField

        init(_ parent: MultilineTextField) {
            self.parent = parent
        }

        func recalcHeight(_ textView: NSTextView) {
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }
            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)
            let inset = textView.textContainerInset.height * 2
            let newHeight = min(max(usedRect.height + inset, parent.minHeight), parent.maxHeight)
            parent.dynamicHeight = newHeight
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? AutoGrowTextView else { return }
            textView.suppressScroll = true
            parent.text = textView.string
            recalcHeight(textView)

            DispatchQueue.main.async {
                textView.suppressScroll = false
                if self.parent.dynamicHeight >= self.parent.maxHeight {
                    textView.scrollRangeToVisible(textView.selectedRange())
                }
            }
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if NSEvent.modifierFlags.contains(.shift) {
                    textView.insertNewlineIgnoringFieldEditor(nil)
                    return true
                } else {
                    parent.onSubmit()
                    return true
                }
            }
            return false
        }
    }
}

#Preview {
    ContentView(store: QueueStore())
}
