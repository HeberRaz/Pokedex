//
//  FeatureControlEvaluatorTests.swift
//  PokedexTests
//
//  Created by Heber Alvarez on 12/02/26.
//

import XCTest
@testable import Pokedex

final class FeatureControlEvaluatorTests: XCTestCase {

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

    // MARK: - Helpers

    private func makeSnapshot(controls: [FeatureControlDTO]) -> FeatureControlsSnapshot {
        FeatureControlsSnapshot(schemaVersion: 1, controls: controls)
    }

    // MARK: - Tests

    func test_flag_enabledTrue_returnsTrue() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "flag_a", type: .flag, enabled: true)
        ])

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: 0)
        )

        XCTAssertTrue(evaluator.isEnabled(flagId: "flag_a", snapshot: snapshot))
    }

    func test_flag_notFound_returnsFalse() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "flag_a", type: .flag, enabled: true)
        ])

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: 0)
        )

        XCTAssertFalse(evaluator.isEnabled(flagId: "flag_missing", snapshot: snapshot))
    }

    func test_rollout_enabled_bucketInsidePercentage_returnsTrue() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "rollout_a", type: .rollout, enabled: true, percentage: 20)
        ])

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: 5) // < 20
        )

        XCTAssertTrue(evaluator.isIncludedInRollout(rolloutId: "rollout_a", snapshot: snapshot))
    }

    func test_rollout_enabled_bucketOutsidePercentage_returnsFalse() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "rollout_a", type: .rollout, enabled: true, percentage: 20)
        ])

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: 25) // >= 20
        )

        XCTAssertFalse(evaluator.isIncludedInRollout(rolloutId: "rollout_a", snapshot: snapshot))
    }

    func test_rollout_disabled_returnsFalse_evenIfBucketInside() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "rollout_a", type: .rollout, enabled: false, percentage: 20)
        ])

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: 5)
        )

        XCTAssertFalse(evaluator.isIncludedInRollout(rolloutId: "rollout_a", snapshot: snapshot))
    }

    func test_rollout_invalidPercentage_returnsFalse() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "rollout_a", type: .rollout, enabled: true, percentage: 999)
        ])

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: 0)
        )

        XCTAssertFalse(evaluator.isIncludedInRollout(rolloutId: "rollout_a", snapshot: snapshot))
    }

    func test_experiment_variant_returnsA_whenBucketFallsInAWeight() {
        let snapshot = makeSnapshot(controls: [
            .init(
                id: "exp_a",
                type: .experiment,
                enabled: true,
                variants: ["A": 50, "B": 50]
            )
        ])

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: 10) // falls into A (0..<50)
        )

        XCTAssertEqual(evaluator.variant(for: "exp_a", snapshot: snapshot), .a)
    }

    func test_experiment_variant_returnsB_whenBucketFallsInBWeight() {
        let snapshot = makeSnapshot(controls: [
            .init(
                id: "exp_a",
                type: .experiment,
                enabled: true,
                variants: ["A": 50, "B": 50]
            )
        ])

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: 80) // falls into B
        )

        XCTAssertEqual(evaluator.variant(for: "exp_a", snapshot: snapshot), .b)
    }

    func test_experiment_disabled_returnsNil() {
        let snapshot = makeSnapshot(controls: [
            .init(
                id: "exp_a",
                type: .experiment,
                enabled: false,
                variants: ["A": 50, "B": 50]
            )
        ])

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: 10)
        )

        XCTAssertNil(evaluator.variant(for: "exp_a", snapshot: snapshot))
    }

    func test_throttle_config_returnsConfig_whenEnabledAndHasMax() {
        let snapshot = makeSnapshot(controls: [
            .init(
                id: "throttle_a",
                type: .throttle,
                enabled: true,
                maxPerMinute: 3
            )
        ])

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: 0)
        )

        let config = evaluator.throttleConfig(for: "throttle_a", snapshot: snapshot)
        XCTAssertEqual(config?.maxPerMinute, 3)
    }

    func test_throttle_disabled_returnsNil() {
        let snapshot = makeSnapshot(controls: [
            .init(
                id: "throttle_a",
                type: .throttle,
                enabled: false,
                maxPerMinute: 3
            )
        ])

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: 0)
        )

        XCTAssertNil(evaluator.throttleConfig(for: "throttle_a", snapshot: snapshot))
    }
}
