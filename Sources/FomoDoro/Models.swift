import Foundation
import SwiftData

enum SessionKind: String, Codable, CaseIterable {
    case focus
    case shortBreak
    case longBreak
}

@Model
final class FocusSession {
    var kindRaw: String
    var start: Date
    var durationSeconds: Int
    var taskTitle: String?

    init(kind: SessionKind, start: Date, durationSeconds: Int, taskTitle: String?) {
        self.kindRaw = kind.rawValue
        self.start = start
        self.durationSeconds = durationSeconds
        self.taskTitle = taskTitle
    }

    var kind: SessionKind { SessionKind(rawValue: kindRaw) ?? .focus }
}

@Model
final class TaskItem {
    var title: String
    var estimate: Int
    var completed: Int
    var isDone: Bool
    var completedAt: Date?
    var createdAt: Date
    var sortOrder: Int

    init(title: String, estimate: Int, sortOrder: Int) {
        self.title = title
        self.estimate = estimate
        self.completed = 0
        self.isDone = false
        self.completedAt = nil
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}
