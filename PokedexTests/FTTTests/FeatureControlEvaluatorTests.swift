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

    private func makeEvaluator(bucket: Int) -> DefaultFeatureControlEvaluator {
        DefaultFeatureControlEvaluator(
            identityProvider: FakeIdentityProvider(stableID: "user-1"),
            bucketer: FakeBucketer(fixedBucket: bucket)
        )
    }

    // MARK: - Tests

    func test_flag_enabledTrue_returnsTrue() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "flag_a", type: .flag, enabled: true)
        ])

        let evaluator = makeEvaluator(bucket: 0)

        XCTAssertTrue(evaluator.isEnabled(flagId: "flag_a", snapshot: snapshot))
    }

    func test_flag_notFound_returnsFalse() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "flag_a", type: .flag, enabled: true)
        ])

        let evaluator = makeEvaluator(bucket: 0)

        XCTAssertFalse(evaluator.isEnabled(flagId: "flag_missing", snapshot: snapshot))
    }

    // MARK: - Rollout

    func test_rollout_enabled_bucketInsidePercentage_returnsIncludedTrue_andMetadata() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "rollout_a", type: .rollout, enabled: true, percentage: 20)
        ])

        let evaluator = makeEvaluator(bucket: 5) // < 20

        let result = evaluator.evaluateRollout(rolloutId: "rollout_a", snapshot: snapshot)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.included, true)
        XCTAssertEqual(result?.bucket, 5)
        XCTAssertEqual(result?.percentage, 20)
    }

    func test_rollout_enabled_bucketOutsidePercentage_returnsIncludedFalse_andMetadata() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "rollout_a", type: .rollout, enabled: true, percentage: 20)
        ])

        let evaluator = makeEvaluator(bucket: 25) // >= 20

        let result = evaluator.evaluateRollout(rolloutId: "rollout_a", snapshot: snapshot)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.included, false)
        XCTAssertEqual(result?.bucket, 25)
        XCTAssertEqual(result?.percentage, 20)
    }

    func test_rollout_disabled_returnsNil_evenIfBucketInside() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "rollout_a", type: .rollout, enabled: false, percentage: 20)
        ])

        let evaluator = makeEvaluator(bucket: 5)

        XCTAssertNil(evaluator.evaluateRollout(rolloutId: "rollout_a", snapshot: snapshot))
    }

    func test_rollout_invalidPercentage_returnsNil() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "rollout_a", type: .rollout, enabled: true, percentage: 999)
        ])

        let evaluator = makeEvaluator(bucket: 0)

        XCTAssertNil(evaluator.evaluateRollout(rolloutId: "rollout_a", snapshot: snapshot))
    }

    func test_rollout_notFound_returnsNil() {
        let snapshot = makeSnapshot(controls: [
            .init(id: "rollout_a", type: .rollout, enabled: true, percentage: 20)
        ])

        let evaluator = makeEvaluator(bucket: 0)

        XCTAssertNil(evaluator.evaluateRollout(rolloutId: "rollout_missing", snapshot: snapshot))
    }

    // MARK: - Experiment

    func test_experiment_variant_returnsA_whenBucketFallsInAWeight_andMetadata() {
        let snapshot = makeSnapshot(controls: [
            .init(
                id: "exp_a",
                type: .experiment,
                enabled: true,
                variants: ["A": 50, "B": 50]
            )
        ])

        let evaluator = makeEvaluator(bucket: 10) // 0..<50 -> A

        let result = evaluator.evaluateExperiment(experimentId: "exp_a", snapshot: snapshot)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.variant, .a)
        XCTAssertEqual(result?.bucket, 10)
        XCTAssertEqual(result?.weights["A"], 50)
        XCTAssertEqual(result?.weights["B"], 50)
        XCTAssertEqual(result?.totalWeight, 100)
        XCTAssertEqual(result?.thresholdA, 50)
    }

    func test_experiment_variant_returnsB_whenBucketFallsInBWeight_andMetadata() {
        let snapshot = makeSnapshot(controls: [
            .init(
                id: "exp_a",
                type: .experiment,
                enabled: true,
                variants: ["A": 50, "B": 50]
            )
        ])

        let evaluator = makeEvaluator(bucket: 80) // 50..<100 -> B

        let result = evaluator.evaluateExperiment(experimentId: "exp_a", snapshot: snapshot)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.variant, .b)
        XCTAssertEqual(result?.bucket, 80)
        XCTAssertEqual(result?.thresholdA, 50)
        XCTAssertEqual(result?.totalWeight, 100)
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

        let evaluator = makeEvaluator(bucket: 10)

        XCTAssertNil(evaluator.evaluateExperiment(experimentId: "exp_a", snapshot: snapshot))
    }

    func test_experiment_emptyVariants_returnsNil() {
        let snapshot = makeSnapshot(controls: [
            .init(
                id: "exp_a",
                type: .experiment,
                enabled: true,
                variants: [:]
            )
        ])

        let evaluator = makeEvaluator(bucket: 10)

        XCTAssertNil(evaluator.evaluateExperiment(experimentId: "exp_a", snapshot: snapshot))
    }

    func test_experiment_totalWeightZero_returnsNil() {
        let snapshot = makeSnapshot(controls: [
            .init(
                id: "exp_a",
                type: .experiment,
                enabled: true,
                variants: ["A": 0, "B": 0]
            )
        ])

        let evaluator = makeEvaluator(bucket: 10)

        XCTAssertNil(evaluator.evaluateExperiment(experimentId: "exp_a", snapshot: snapshot))
    }

    func test_experiment_notFound_returnsNil() {
        let snapshot = makeSnapshot(controls: [
            .init(
                id: "exp_a",
                type: .experiment,
                enabled: true,
                variants: ["A": 50, "B": 50]
            )
        ])

        let evaluator = makeEvaluator(bucket: 10)

        XCTAssertNil(evaluator.evaluateExperiment(experimentId: "exp_missing", snapshot: snapshot))
    }

    // MARK: - Throttle

    func test_throttle_config_returnsConfig_whenEnabledAndHasMax() {
        let snapshot = makeSnapshot(controls: [
            .init(
                id: "throttle_a",
                type: .throttle,
                enabled: true,
                maxPerMinute: 3
            )
        ])

        let evaluator = makeEvaluator(bucket: 0)

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

        let evaluator = makeEvaluator(bucket: 0)

        XCTAssertNil(evaluator.throttleConfig(for: "throttle_a", snapshot: snapshot))
    }
}
