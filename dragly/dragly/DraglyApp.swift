import SwiftUI

@main
struct DraglyApp: App {
    @StateObject private var store = QueueStore()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Window("drag.ly", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 320, minHeight: 300)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 320, height: 400)

        MenuBarExtra("drag.ly", systemImage: "square.stack.3d.up") {
            Button("Show Window") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Divider()

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
            .keyboardShortcut("q")
        }
    }
}
