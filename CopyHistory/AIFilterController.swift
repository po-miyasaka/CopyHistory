import Foundation

struct JudgeCandidate: Equatable {
    let id: String
    let text: String
}

struct JudgeOutcome: Equatable, Sendable {
    /// Candidates that match the criterion.
    let matchedIDs: Set<String>
    /// Candidates that could not be judged (they are retried later and never cached).
    let failedIDs: Set<String>
}

protocol ItemJudge: Sendable {
    func judge(criterion: String, candidates: [JudgeCandidate]) async throws -> JudgeOutcome
}

/// Filters items by a free-form criterion, judged in small batches by an `ItemJudge`.
///
/// Candidates are judged in the order given and judging stops as soon as `limit` matches are found,
/// so the whole history can be searched without judging every item when matches are plentiful.
/// Verdicts are cached per criterion, so re-applying a criterion only judges what is new.
@MainActor
final class AIFilterController: ObservableObject {
    struct Progress: Equatable {
        let done: Int
        let total: Int
    }

    static let batchSize = 4

    @Published private(set) var query = ""
    @Published private(set) var limit = Int.max
    @Published private(set) var progress: Progress?
    @Published private(set) var matchCount = 0
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

    /// True when the run ended because enough matches were found.
    var reachedLimit: Bool { isActive && progress == nil && matchCount >= limit }

    func isMatch(id: String) -> Bool {
        verdicts[Self.key(query, id)] == true
    }

    func apply(query: String, candidates: [JudgeCandidate], limit: Int) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clear()
            return
        }
        self.query = trimmed
        self.limit = max(limit, 1)
        failedCount = 0
        isStopped = false
        judgePending(candidates)
    }

    /// Judges items that appeared since the criterion was applied.
    func refresh(candidates: [JudgeCandidate], limit: Int) {
        guard isActive, !isStopped else { return }
        self.limit = max(limit, 1)
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
        limit = Int.max
        progress = nil
        matchCount = 0
        failedCount = 0
        isStopped = false
    }

    private func judgePending(_ candidates: [JudgeCandidate]) {
        task?.cancel()
        let criterion = query
        let limit = self.limit
        let pendingTotal = candidates.filter { verdicts[Self.key(criterion, $0.id)] == nil }.count
        matchCount = Self.countMatches(in: candidates, verdicts: verdicts, criterion: criterion)
        guard !Self.nextBatch(in: candidates, verdicts: verdicts, skipped: [], criterion: criterion, limit: limit).isEmpty else {
            progress = nil
            return
        }
        guard let judge = makeJudge() else {
            failedCount += pendingTotal
            progress = nil
            return
        }

        progress = Progress(done: 0, total: pendingTotal)
        task = Task { [weak self] in
            var done = 0
            var skipped = Set<String>() // items that failed in this run are not retried until the next one
            while !Task.isCancelled, let self {
                let known = self.verdicts
                self.matchCount = Self.countMatches(in: candidates, verdicts: known, criterion: criterion)
                let batch = Self.nextBatch(in: candidates, verdicts: known, skipped: skipped, criterion: criterion, limit: limit)
                if batch.isEmpty { break }

                do {
                    let outcome = try await judge.judge(criterion: criterion, candidates: batch)
                    guard !Task.isCancelled else { return }
                    var updated = self.verdicts
                    for candidate in batch where !outcome.failedIDs.contains(candidate.id) {
                        updated[Self.key(criterion, candidate.id)] = outcome.matchedIDs.contains(candidate.id)
                    }
                    self.verdicts = updated
                    skipped.formUnion(outcome.failedIDs)
                    self.failedCount += outcome.failedIDs.count
                } catch is CancellationError {
                    return
                } catch {
                    guard !Task.isCancelled else { return }
                    NSLog("AI filter could not judge a batch: \(error)")
                    skipped.formUnion(batch.map(\.id))
                    self.failedCount += batch.count
                }
                done += batch.count
                guard !Task.isCancelled else { return }
                self.progress = Progress(done: done, total: pendingTotal)
            }
            guard !Task.isCancelled, let self else { return }
            self.matchCount = Self.countMatches(in: candidates, verdicts: self.verdicts, criterion: criterion)
            self.progress = nil
        }
    }

    /// The next unjudged candidates, in order, that come before the position where `limit` matches are reached.
    private static func nextBatch(
        in candidates: [JudgeCandidate],
        verdicts: [String: Bool],
        skipped: Set<String>,
        criterion: String,
        limit: Int
    ) -> [JudgeCandidate] {
        var batch: [JudgeCandidate] = []
        var matches = 0
        for candidate in candidates {
            if matches >= limit { break }
            switch verdicts[key(criterion, candidate.id)] {
            case true?:
                matches += 1
            case false?:
                break
            case nil:
                guard !skipped.contains(candidate.id) else { continue }
                batch.append(candidate)
                if batch.count == batchSize { return batch }
            }
        }
        return batch
    }

    private static func countMatches(in candidates: [JudgeCandidate], verdicts: [String: Bool], criterion: String) -> Int {
        candidates.reduce(0) { $0 + (verdicts[key(criterion, $1.id)] == true ? 1 : 0) }
    }

    private static func key(_ query: String, _ id: String) -> String {
        "\(query)\u{1F}\(id)"
    }
}
