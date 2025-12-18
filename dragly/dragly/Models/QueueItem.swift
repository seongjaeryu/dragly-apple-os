import Foundation

struct QueueItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var isChecked: Bool
    let createdAt: Date

    init(id: UUID = UUID(), text: String, isChecked: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.isChecked = isChecked
        self.createdAt = createdAt
    }
}
