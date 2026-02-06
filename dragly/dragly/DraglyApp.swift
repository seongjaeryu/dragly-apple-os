import SwiftUI

@main
struct DraglyApp: App {
    @StateObject private var store = QueueStore()

    var body: some Scene {
        MenuBarExtra("drag.ly", systemImage: "doc.on.clipboard") {
            ContentView(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}
