import SwiftUI

struct ContentView: View {
    @ObservedObject var store: QueueStore
    @State private var newText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("drag.ly")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                if store.items.contains(where: { $0.isUsed }) {
                    Button("Clear Used") {
                        store.clearUsed()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            .padding()

            Divider()

            // Items list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(store.items) { item in
                        CardRow(item: item, store: store)
                    }
                }
                .padding()
            }

            Divider()

            // Input (Shift+Enter for newline, Enter to submit)
            HStack(alignment: .bottom) {
                MultilineTextField(text: $newText, onSubmit: addItem)
                    .frame(minHeight: 20, maxHeight: 80)

                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(newText.isEmpty ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .disabled(newText.isEmpty)
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func addItem() {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.add(trimmed)
        newText = ""
    }
}

struct CardRow: View {
    let item: QueueItem
    @ObservedObject var store: QueueStore
    @State private var isHovering = false

    var body: some View {
        HStack {
            // Drag indicator
            Image(systemName: item.isUsed ? "checkmark.circle.fill" : "line.3.horizontal")
                .foregroundColor(item.isUsed ? .green : .secondary)
                .frame(width: 20)

            // Text
            Text(item.text)
                .strikethrough(item.isUsed)
                .foregroundColor(item.isUsed ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Copy & Delete buttons
            if isHovering || item.isUsed {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.text, forType: .string)
                    store.markUsed(item.id)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")

                Button {
                    store.remove(item.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .opacity(item.isUsed ? 0.6 : 1)
        .onHover { isHovering = $0 }
        .onDrag {
            store.markUsed(item.id)
            return NSItemProvider(object: item.text as NSString)
        }
    }
}

// MARK: - Multiline TextField (Enter to submit, Shift+Enter for newline)
struct MultilineTextField: NSViewRepresentable {
    @Binding var text: String
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 13)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 0, height: 4)

        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
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

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                // Check if Shift is pressed
                if NSEvent.modifierFlags.contains(.shift) {
                    // Shift+Enter: insert newline
                    textView.insertNewlineIgnoringFieldEditor(nil)
                    return true
                } else {
                    // Enter: submit
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
        .frame(width: 320, height: 400)
}
