import Foundation
import Combine

enum SessionKind: String, Codable, CaseIterable {
    case focus
    case shortBreak
    case longBreak
}

struct FocusSession: Identifiable, Codable, Equatable {
    let id: UUID
    var kindRaw: String
    var start: Date
    var durationSeconds: Int
    var taskTitle: String?

    init(kind: SessionKind, start: Date, durationSeconds: Int, taskTitle: String?) {
        id = UUID()
        kindRaw = kind.rawValue
        self.start = start
        self.durationSeconds = durationSeconds
        self.taskTitle = taskTitle
    }

    var kind: SessionKind { SessionKind(rawValue: kindRaw) ?? .focus }
}

final class TaskItem: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var title: String
    @Published var estimate: Int
    @Published var completed: Int
    @Published var isDone: Bool
    @Published var completedAt: Date?
    let createdAt: Date
    var sortOrder: Int

    init(title: String, estimate: Int, sortOrder: Int) {
        id = UUID()
        self.title = title
        self.estimate = estimate
        completed = 0
        isDone = false
        completedAt = nil
        createdAt = Date()
        self.sortOrder = sortOrder
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, estimate, completed, isDone, completedAt, createdAt, sortOrder
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        estimate = try values.decode(Int.self, forKey: .estimate)
        completed = try values.decode(Int.self, forKey: .completed)
        isDone = try values.decode(Bool.self, forKey: .isDone)
        completedAt = try values.decodeIfPresent(Date.self, forKey: .completedAt)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        sortOrder = try values.decode(Int.self, forKey: .sortOrder)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(title, forKey: .title)
        try values.encode(estimate, forKey: .estimate)
        try values.encode(completed, forKey: .completed)
        try values.encode(isDone, forKey: .isDone)
        try values.encodeIfPresent(completedAt, forKey: .completedAt)
        try values.encode(createdAt, forKey: .createdAt)
        try values.encode(sortOrder, forKey: .sortOrder)
    }
}

@MainActor
final class LegacyDataStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var sessions: [FocusSession] = []

    private struct Snapshot: Codable {
        var tasks: [TaskItem]
        var sessions: [FocusSession]
    }

    private let storeURL: URL

    init() {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("FomoDoro Legacy", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        storeURL = directory.appendingPathComponent("data.json")
        load()
    }

    func addTask(title: String, estimate: Int) {
        let order = (tasks.map(\.sortOrder).max() ?? 0) + 1
        tasks.append(TaskItem(title: title, estimate: estimate, sortOrder: order))
        save()
    }

    func delete(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    func addSession(_ session: FocusSession) {
        sessions.append(session)
        save()
    }

    func save() {
        objectWillChange.send()
        let snapshot = Snapshot(tasks: tasks, sessions: sessions)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }
        tasks = snapshot.tasks.sorted { $0.sortOrder < $1.sortOrder }
        sessions = snapshot.sessions.sorted { $0.start > $1.start }
    }
}
