import SwiftUI

struct QueueItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var isUsed: Bool

    init(id: UUID = UUID(), text: String, isUsed: Bool = false) {
        self.id = id
        self.text = text
        self.isUsed = isUsed
    }
}

class QueueStore: ObservableObject {
    @Published var items: [QueueItem] = []

    private let key = "dragly.items"

    init() {
        load()
    }

    func add(_ text: String) {
        let item = QueueItem(text: text)
        items.insert(item, at: 0)
        save()
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func markUsed(_ id: UUID) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].isUsed = true
            save()
        }
    }

    func toggleUsed(_ id: UUID) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].isUsed.toggle()
            save()
        }
    }

    func clearUsed() {
        items.removeAll { $0.isUsed }
        save()
    }

    func clearAll() {
        items.removeAll()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([QueueItem].self, from: data) {
            items = decoded
        }
    }
}
