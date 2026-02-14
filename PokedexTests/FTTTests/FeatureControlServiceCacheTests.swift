//
//  FeatureControlServiceCacheTests.swift
//  PokedexTests
//
//  Created by GitHub Copilot on 14/02/26.
//

import XCTest
@testable import Pokedex

final class FeatureControlServiceCacheTests: XCTestCase {

    private struct TestError: Error {}

    private final class RepositoryStub: FeatureControlRepository {
        enum Mode {
            case success(FeatureControlsSnapshot)
            case failure(Error)
        }

        var mode: Mode
        private(set) var fetchCalls: Int = 0

        init(mode: Mode) {
            self.mode = mode
        }

        func fetchSnapshot() async throws -> FeatureControlsSnapshot {
            fetchCalls += 1
            switch mode {
                case .success(let snapshot): return snapshot
                case .failure(let error): throw error
            }
        }
    }

    private final class InMemorySnapshotStore: FeatureControlsSnapshotStore {
        var stored: FeatureControlsSnapshot?
        func load() throws -> FeatureControlsSnapshot? { stored }
        func save(_ snapshot: FeatureControlsSnapshot) throws { stored = snapshot }
    }

    private func makeSnapshot(id: String = "flag_a", enabled: Bool = true) -> FeatureControlsSnapshot {
        FeatureControlsSnapshot(
            schemaVersion: 1,
            controls: [.init(id: id, type: .flag, enabled: enabled)]
        )
    }

    func test_refresh_usesTTL_toAvoidMultipleRepositoryHits() async throws {
        let snapshot = makeSnapshot()
        let repo = RepositoryStub(mode: .success(snapshot))
        let store = InMemorySnapshotStore()

        let evaluator = EvaluatorStub()
        evaluator.flagValue["flag_a"] = true

        let sut = DefaultFeatureControlService(
            repository: repo,
            evaluator: evaluator,
            overrideStore: OverrideStoreStub(),
            decisionTracer: NoopDecisionTracer(),
            snapshotStore: store,
            minimumRefreshInterval: 60
        )

        try await sut.refresh()
        try await sut.refresh() // second call within TTL should be a no-op

        XCTAssertEqual(repo.fetchCalls, 1)
        XCTAssertTrue(sut.isEnabled("flag_a"))
    }

    func test_refresh_onFailure_usesCachedSnapshotFromStore_whenNoInMemorySnapshot() async throws {
        let cachedSnapshot = makeSnapshot(id: "from_cache")
        let repo = RepositoryStub(mode: .failure(TestError()))
        let store = InMemorySnapshotStore()
        store.stored = cachedSnapshot

        let evaluator = EvaluatorStub()
        evaluator.flagValue["from_cache"] = true

        let sut = DefaultFeatureControlService(
            repository: repo,
            evaluator: evaluator,
            overrideStore: OverrideStoreStub(),
            decisionTracer: NoopDecisionTracer(),
            snapshotStore: store,
            minimumRefreshInterval: 0
        )

        // First refresh fails remotely but should hydrate from cache and not throw.
        try await sut.refresh()

        XCTAssertTrue(sut.isEnabled("from_cache"))
    }
}
