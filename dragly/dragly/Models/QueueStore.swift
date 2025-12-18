import Foundation
import Combine

class QueueStore: ObservableObject {
    static let shared = QueueStore()

    private let userDefaultsKey = "dragly.queueItems"

    @Published var items: [QueueItem] = []

    private init() {
        load()
    }

    // MARK: - CRUD Operations

    func addItem(text: String) {
        let item = QueueItem(text: text)
        items.insert(item, at: 0)
        save()
    }

    func updateItem(id: UUID, text: String) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].text = text
            save()
        }
    }

    func toggleChecked(id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isChecked.toggle()
            save()
        }
    }

    func markAsChecked(id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isChecked = true
            save()
        }
    }

    func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func clearCompleted() {
        items.removeAll { $0.isChecked }
        save()
    }

    func clearAll() {
        items.removeAll()
        save()
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: - Persistence

    func save() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save queue items: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        do {
            items = try JSONDecoder().decode([QueueItem].self, from: data)
        } catch {
            print("Failed to load queue items: \(error)")
        }
    }
}
