import Foundation

struct TranscriptionEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let createdAt: Date
    /// Recording duration in seconds, if available.
    let durationSeconds: TimeInterval?
    /// Name of the app text was inserted into, if available.
    let targetAppName: String?

    init(id: UUID = UUID(), text: String, createdAt: Date = Date(), durationSeconds: TimeInterval? = nil, targetAppName: String? = nil) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.durationSeconds = durationSeconds
        self.targetAppName = targetAppName
    }
}
