//
//  FeatureControlExampleJsonIntegrationTests.swift
//  PokedexTests
//
//  Created to validate the full feature-control stack using the example JSON.
//

import XCTest
@testable import Pokedex

final class FeatureControlExampleJsonIntegrationTests: XCTestCase {

    // MARK: - Fakes

    private struct FakeIdentityProvider: UserIdentityProvider {
        let stableID: String
    }

    private final class FakeBucketer: DeterministicBucketer {
        var fixedBucket: Int

        init(fixedBucket: Int) {
            self.fixedBucket = fixedBucket
        }

        func bucket(for controlId: String, userId: String) -> Int {
            fixedBucket
        }
    }

    private struct StaticSnapshotRepository: FeatureControlRepository {
        let snapshot: FeatureControlsSnapshot

        func fetchSnapshot() async throws -> FeatureControlsSnapshot {
            snapshot
        }
    }

    // MARK: - Helpers

    private func makeSnapshotFromExampleJSON() throws -> FeatureControlsSnapshot {
        let json = """
        {
            "schemaVersion": 1,
            "controls": [
                { "id": "checkout_new_flow", "type": "flag", "enabled": false },

                {
                    "id": "checkout_new_flow_rollout",
                    "type": "rollout",
                    "percentage": 20,
                    "enabled": true
                },

                {
                    "id": "home_header_experiment",
                    "type": "experiment",
                    "enabled": true,
                    "variants": { "A": 50, "B": 50 }
                },

                {
                    "id": "login_attempts",
                    "type": "throttle",
                    "enabled": true,
                    "maxPerMinute": 3
                }
            ]
        }
        """

        let data = Data(json.utf8)
        return try JSONDecoder().decode(FeatureControlsSnapshot.self, from: data)
    }

    private func makeService(bucket: Int, overrideStore: LocalOverrideStore) throws -> FeatureControlAdvancedService {
        let snapshot = try makeSnapshotFromExampleJSON()
        let repository = StaticSnapshotRepository(snapshot: snapshot)
        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: bucket)
        )

        return DefaultFeatureControlService(
            repository: repository,
            evaluator: evaluator,
            overrideStore: overrideStore,
            decisionTracer: NoopDecisionTracer(),
            snapshotStore: nil,
            minimumRefreshInterval: 0
        )
    }

    // MARK: - Tests

    func test_flag_and_overrides_withExampleJSON() async throws {
        let overrides = OverrideStoreStub()
        let service = try makeService(bucket: 0, overrideStore: overrides)

        try await service.refresh()

        // From JSON: enabled = false
        XCTAssertFalse(service.isEnabled("checkout_new_flow"))

        // Local override forces it ON
        overrides.setBoolOverride(true, for: "checkout_new_flow")
        XCTAssertTrue(service.isEnabled("checkout_new_flow"))
    }

    func test_rollout_and_percentageOverride_withExampleJSON() async throws {
        let overrides = OverrideStoreStub()
        // Fixed bucket 15, inside remote 20%
        let service = try makeService(bucket: 15, overrideStore: overrides)

        try await service.refresh()

        // With remote 20% and bucket 15 -> included
        XCTAssertTrue(service.isEnabled("checkout_new_flow_rollout"))

        // Override rollout percentage to 10%: bucket 15 >= 10 -> excluded
        overrides.setRolloutPercentageOverride(10, for: "checkout_new_flow_rollout")
        XCTAssertFalse(service.isEnabled("checkout_new_flow_rollout"))

        // Bool override still wins over percentage
        overrides.setBoolOverride(true, for: "checkout_new_flow_rollout")
        XCTAssertTrue(service.isEnabled("checkout_new_flow_rollout"))
    }

    func test_experiment_variant_withExampleJSON() async throws {
        let overrides = OverrideStoreStub()
        // Bucket 10 -> A (50/50 split)
        let serviceA = try makeService(bucket: 10, overrideStore: overrides)
        try await serviceA.refresh()
        XCTAssertEqual(serviceA.variant(for: "home_header_experiment"), .a)

        // Bucket 80 -> B
        let serviceB = try makeService(bucket: 80, overrideStore: overrides)
        try await serviceB.refresh()
        XCTAssertEqual(serviceB.variant(for: "home_header_experiment"), .b)

        // Local override forces variant regardless of bucket
        overrides.setVariantOverride(.a, for: "home_header_experiment")
        XCTAssertEqual(serviceB.variant(for: "home_header_experiment"), .a)
    }

    func test_throttle_and_override_withExampleJSON() async throws {
        let overrides = OverrideStoreStub()
        let service = try makeService(bucket: 0, overrideStore: overrides)

        try await service.refresh()

        // From JSON: maxPerMinute = 3
        XCTAssertEqual(service.throttleConfig(for: "login_attempts")?.maxPerMinute, 3)

        // Local override increases limit
        overrides.setThrottleOverride(ThrottleConfig(maxPerMinute: 10), for: "login_attempts")
        XCTAssertEqual(service.throttleConfig(for: "login_attempts")?.maxPerMinute, 10)
    }

    func test_controlsCount_matchesExampleJSON() async throws {
        let overrides = OverrideStoreStub()
        let service = try makeService(bucket: 0, overrideStore: overrides)

        try await service.refresh()
        XCTAssertEqual(service.controlsCount(), 4)
    }
}
