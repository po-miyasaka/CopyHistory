import Foundation

struct JudgeCandidate: Equatable {
    let id: String
    let text: String
}

protocol ItemJudge: Sendable {
    /// Returns the ids of the candidates that match the criterion.
    func matches(criterion: String, in candidates: [JudgeCandidate]) async throws -> Set<String>
}

/// Filters items by a free-form criterion, judged in small batches by an `ItemJudge`.
/// Verdicts are cached per criterion, so re-applying a criterion only judges new items.
@MainActor
final class AIFilterController: ObservableObject {
    struct Progress: Equatable {
        let done: Int
        let total: Int
    }

    static let batchSize = 4

    @Published private(set) var query = ""
    @Published private(set) var progress: Progress?
    @Published private(set) var failedCount = 0
    /// True after the user stopped a run: judging does not resume on its own until the criterion is applied again.
    @Published private(set) var isStopped = false
    @Published private(set) var verdicts: [String: Bool] = [:]

    private let makeJudge: () -> ItemJudge?
    private var task: Task<Void, Never>?

    init(makeJudge: @escaping () -> ItemJudge?) {
        self.makeJudge = makeJudge
    }

    var isActive: Bool { !query.isEmpty }

    func isMatch(id: String) -> Bool {
        verdicts[Self.key(query, id)] == true
    }

    func apply(query: String, candidates: [JudgeCandidate]) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clear()
            return
        }
        self.query = trimmed
        failedCount = 0
        isStopped = false
        judgePending(candidates)
    }

    /// Judges items that appeared since the criterion was applied.
    func refresh(candidates: [JudgeCandidate]) {
        guard isActive, !isStopped else { return }
        judgePending(candidates)
    }

    /// Stops judging but keeps the criterion and the verdicts gathered so far.
    func stop() {
        task?.cancel()
        task = nil
        progress = nil
        isStopped = true
    }

    func clear() {
        task?.cancel()
        task = nil
        query = ""
        progress = nil
        failedCount = 0
        isStopped = false
    }

    private func judgePending(_ candidates: [JudgeCandidate]) {
        task?.cancel()
        let criterion = query
        let pending = candidates.filter { verdicts[Self.key(criterion, $0.id)] == nil }
        guard !pending.isEmpty else {
            progress = nil
            return
        }
        guard let judge = makeJudge() else {
            failedCount += pending.count
            progress = nil
            return
        }

        progress = Progress(done: 0, total: pending.count)
        let batches = stride(from: 0, to: pending.count, by: Self.batchSize).map {
            Array(pending[$0..<min($0 + Self.batchSize, pending.count)])
        }
        task = Task { [weak self] in
            var done = 0
            for batch in batches {
                guard !Task.isCancelled else { return }
                do {
                    let matched = try await judge.matches(criterion: criterion, in: batch)
                    guard !Task.isCancelled, let self else { return }
                    var updated = self.verdicts
                    for candidate in batch {
                        updated[Self.key(criterion, candidate.id)] = matched.contains(candidate.id)
                    }
                    self.verdicts = updated
                } catch is CancellationError {
                    return
                } catch {
                    guard !Task.isCancelled, let self else { return }
                    NSLog("AI filter could not judge a batch: \(error)")
                    self.failedCount += batch.count
                }
                done += batch.count
                guard !Task.isCancelled else { return }
                self?.progress = Progress(done: done, total: pending.count)
            }
            guard !Task.isCancelled else { return }
            self?.progress = nil
        }
    }

    private static func key(_ query: String, _ id: String) -> String {
        "\(query)\u{1F}\(id)"
    }
}
