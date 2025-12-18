import SwiftUI
import UniformTypeIdentifiers

struct CardView: View {
    let item: QueueItem
    let onUpdate: (String) -> Void
    let onDelete: () -> Void
    let onDragComplete: () -> Void

    @State private var isEditing: Bool = false
    @State private var editText: String = ""
    @State private var isHovering: Bool = false
    @State private var isDragging: Bool = false

    // Animation states
    private var cardHeight: CGFloat {
        item.isChecked ? 32 : 60
    }

    private var cardOpacity: Double {
        item.isChecked ? 0.5 : 1.0
    }

    var body: some View {
        HStack(spacing: 8) {
            // Drag handle / Check indicator
            dragHandleView

            // Content
            contentView

            // Delete button
            if isHovering || item.isChecked {
                deleteButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, item.isChecked ? 6 : 10)
        .frame(height: cardHeight)
        .background(cardBackground)
        .cornerRadius(8)
        .opacity(cardOpacity)
        .onHover { hovering in
            isHovering = hovering
        }
        .onDrag {
            isDragging = true
            // Create NSItemProvider with plain text
            let provider = NSItemProvider(object: item.text as NSString)
            return provider
        }
        .onChange(of: isDragging) { _, newValue in
            if !newValue {
                // Drag ended - this will be called after drop
                // Note: We mark as checked when drag starts to provide immediate feedback
            }
        }
        .animation(.easeInOut(duration: 0.3), value: item.isChecked)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
    }

    // MARK: - Subviews

    private var dragHandleView: some View {
        Group {
            if item.isChecked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green.opacity(0.7))
                    .font(.system(size: 14))
            } else {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
        }
        .frame(width: 20)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !item.isChecked {
                        isDragging = true
                    }
                }
                .onEnded { _ in
                    if isDragging && !item.isChecked {
                        onDragComplete()
                    }
                    isDragging = false
                }
        )
    }

    private var contentView: some View {
        Group {
            if isEditing {
                TextField("", text: $editText, onCommit: {
                    finishEditing()
                })
                .textFieldStyle(.plain)
                .font(item.isChecked ? .caption : .body)
                .onAppear {
                    editText = item.text
                }
            } else {
                Text(item.text)
                    .font(item.isChecked ? .caption : .body)
                    .lineLimit(item.isChecked ? 1 : 2)
                    .strikethrough(item.isChecked, color: .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        if !item.isChecked {
                            startEditing()
                        }
                    }
            }
        }
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary.opacity(0.6))
                .font(.system(size: 14))
        }
        .buttonStyle(.plain)
        .transition(.opacity)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(item.isChecked
                  ? Color.secondary.opacity(0.05)
                  : Color(NSColor.controlBackgroundColor))
            .shadow(color: .black.opacity(isDragging ? 0.2 : 0.05), radius: isDragging ? 8 : 2, y: isDragging ? 4 : 1)
    }

    // MARK: - Actions

    private func startEditing() {
        editText = item.text
        isEditing = true
    }

    private func finishEditing() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onUpdate(trimmed)
        }
        isEditing = false
    }
}

// MARK: - Draggable Card Wrapper for NSPasteboard integration

struct DraggableCard: NSViewRepresentable {
    let text: String
    let onDragComplete: () -> Void

    func makeNSView(context: Context) -> DraggableCardNSView {
        let view = DraggableCardNSView(text: text, onDragComplete: onDragComplete)
        return view
    }

    func updateNSView(_ nsView: DraggableCardNSView, context: Context) {
        nsView.text = text
    }
}

class DraggableCardNSView: NSView, NSDraggingSource {
    var text: String
    var onDragComplete: () -> Void

    init(text: String, onDragComplete: @escaping () -> Void) {
        self.text = text
        self.onDragComplete = onDragComplete
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if operation != [] {
            // Drag was successful
            DispatchQueue.main.async {
                self.onDragComplete()
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(text, forType: .string)

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)

        // Set drag image
        let dragImage = createDragImage()
        draggingItem.setDraggingFrame(bounds, contents: dragImage)

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    private func createDragImage() -> NSImage {
        let size = NSSize(width: max(bounds.width, 100), height: max(bounds.height, 30))
        let image = NSImage(size: size)

        image.lockFocus()

        // Draw background
        NSColor.controlBackgroundColor.setFill()
        let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 6, yRadius: 6)
        path.fill()

        // Draw text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.labelColor
        ]
        let textRect = NSRect(x: 8, y: (size.height - 20) / 2, width: size.width - 16, height: 20)
        text.draw(in: textRect, withAttributes: attributes)

        image.unlockFocus()

        return image
    }
}

#Preview {
    VStack(spacing: 8) {
        CardView(
            item: QueueItem(text: "This is a sample thought"),
            onUpdate: { _ in },
            onDelete: {},
            onDragComplete: {}
        )

        CardView(
            item: QueueItem(text: "This is a checked item", isChecked: true),
            onUpdate: { _ in },
            onDelete: {},
            onDragComplete: {}
        )
    }
    .padding()
    .frame(width: 300)
}
