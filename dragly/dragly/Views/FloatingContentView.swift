import SwiftUI

struct FloatingContentView: View {
    @ObservedObject var queueStore: QueueStore
    @State private var newItemText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Queue list
            queueListView

            Divider()

            // Input area
            inputAreaView
        }
        .frame(minWidth: 280, minHeight: 200)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("drag.ly")
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()

            if queueStore.items.contains(where: { $0.isChecked }) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        queueStore.clearCompleted()
                    }
                }) {
                    Text("Clear Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Queue List

    private var queueListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(queueStore.items) { item in
                    CardView(
                        item: item,
                        onUpdate: { newText in
                            queueStore.updateItem(id: item.id, text: newText)
                        },
                        onDelete: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                queueStore.removeItem(id: item.id)
                            }
                        },
                        onDragComplete: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                queueStore.markAsChecked(id: item.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Input Area

    private var inputAreaView: some View {
        HStack(spacing: 8) {
            TextField("Type a thought and press Enter...", text: $newItemText)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($isInputFocused)
                .onSubmit {
                    addNewItem()
                }

            Button(action: addNewItem) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(newItemText.isEmpty ? .secondary : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(newItemText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Actions

    private func addNewItem() {
        let trimmedText = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            queueStore.addItem(text: trimmedText)
        }
        newItemText = ""
    }
}

#Preview {
    FloatingContentView(queueStore: QueueStore.shared)
        .frame(width: 320, height: 400)
}
