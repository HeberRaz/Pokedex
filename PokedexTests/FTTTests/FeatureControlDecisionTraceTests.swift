//
//  FeatureControlDecisionTraceTests.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//

import XCTest
@testable import Pokedex

final class FeatureControlDecisionTraceTests: XCTestCase {

    // MARK: - Test Doubles

    private final class RepositoryStub: FeatureControlRepository {
        var snapshot: FeatureControlsSnapshot

        init(snapshot: FeatureControlsSnapshot) {
            self.snapshot = snapshot
        }

        func fetchSnapshot() async throws -> FeatureControlsSnapshot {
            snapshot
        }
    }

    private final class DecisionTracerSpy: DecisionTracing {
        private(set) var records: [DecisionTrace] = []
        func record(_ trace: DecisionTrace) { records.append(trace) }
        var last: DecisionTrace? { records.last }
    }

    // MARK: - Helpers

    private func makeSnapshot(_ controls: [FeatureControlDTO]) -> FeatureControlsSnapshot {
        FeatureControlsSnapshot(schemaVersion: 1, controls: controls)
    }

    private func makeSUT(
        snapshot: FeatureControlsSnapshot,
        evaluator: EvaluatorStub = EvaluatorStub(),
        overrides: OverrideStoreStub = OverrideStoreStub(),
        tracer: DecisionTracerSpy = DecisionTracerSpy()
    ) -> (service: DefaultFeatureControlService, tracer: DecisionTracerSpy, evaluator: EvaluatorStub, overrides: OverrideStoreStub) {

        let repo = RepositoryStub(snapshot: snapshot)

        let sut = DefaultFeatureControlService(
            repository: repo,
            evaluator: evaluator,
            overrideStore: overrides,
            decisionTracer: tracer
        )

        return (sut, tracer, evaluator, overrides)
    }

    // MARK: - Missing snapshot

    func test_isEnabled_missingSnapshot_recordsMissingSnapshot_false() {
        let tracer = DecisionTracerSpy()
        let repo = RepositoryStub(snapshot: makeSnapshot([]))
        let evaluator = EvaluatorStub()
        let overrides = OverrideStoreStub()

        // Not calling refresh() => snapshot nil
        let sut = DefaultFeatureControlService(
            repository: repo,
            evaluator: evaluator,
            overrideStore: overrides,
            decisionTracer: tracer
        )

        XCTAssertFalse(sut.isEnabled("flag_a"))

        let t = try? XCTUnwrap(tracer.last)
        XCTAssertEqual(t?.controlId, "flag_a")
        XCTAssertEqual(t?.kind, .bool)
        XCTAssertEqual(t?.reason, .missingSnapshot)
        XCTAssertEqual(t?.outcome, .bool(false))
    }

    // MARK: - Missing control

    func test_isEnabled_missingControl_recordsMissingControl_false() async throws {
        let snapshot = makeSnapshot([.init(id: "flag_a", type: .flag, enabled: true)])
        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot)

        try await sut.refresh()

        XCTAssertFalse(sut.isEnabled("flag_missing"))

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlId, "flag_missing")
        XCTAssertEqual(t.kind, .bool)
        XCTAssertEqual(t.reason, .missingControl)
        XCTAssertEqual(t.outcome, .bool(false))
    }

    // MARK: - Flag

    func test_flag_override_recordsOverride_andOutcomeFromOverride() async throws {
        let snapshot = makeSnapshot([.init(id: "flag_a", type: .flag, enabled: false)])
        let evaluator = EvaluatorStub()
        evaluator.flagValue["flag_a"] = false

        let overrides = OverrideStoreStub()
        overrides.boolOverrides["flag_a"] = true

        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot, evaluator: evaluator, overrides: overrides)
        try await sut.refresh()

        XCTAssertTrue(sut.isEnabled("flag_a"))

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlId, "flag_a")
        XCTAssertEqual(t.controlType, .flag)
        XCTAssertEqual(t.kind, .bool)
        XCTAssertEqual(t.reason, .override)
        XCTAssertEqual(t.outcome, .bool(true))
    }

    func test_flag_snapshotEvaluator_recordsSnapshotEvaluator_andOutcomeFromEvaluator() async throws {
        let snapshot = makeSnapshot([.init(id: "flag_a", type: .flag, enabled: true)])
        let evaluator = EvaluatorStub()
        evaluator.flagValue["flag_a"] = true

        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot, evaluator: evaluator)
        try await sut.refresh()

        XCTAssertTrue(sut.isEnabled("flag_a"))

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlType, .flag)
        XCTAssertEqual(t.reason, .snapshotEvaluator)
        XCTAssertEqual(t.outcome, .bool(true))
    }

    // MARK: - Rollout

    func test_rollout_invalidConfig_recordsInvalidConfig_false() async throws {
        let snapshot = makeSnapshot([.init(id: "rollout_a", type: .rollout, enabled: true, percentage: 20)])
        let evaluator = EvaluatorStub()
        evaluator.rolloutResult["rollout_a"] = nil // forces invalidConfig path

        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot, evaluator: evaluator)
        try await sut.refresh()

        XCTAssertFalse(sut.isEnabled("rollout_a"))

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlType, .rollout)
        XCTAssertEqual(t.kind, .bool)
        XCTAssertEqual(t.reason, .invalidConfig)
        XCTAssertEqual(t.outcome, .bool(false))
    }

    func test_rollout_snapshotEvaluator_recordsBucketAndPercentageMetadata() async throws {
        let snapshot = makeSnapshot([.init(id: "rollout_a", type: .rollout, enabled: true, percentage: 20)])
        let evaluator = EvaluatorStub()
        evaluator.rolloutResult["rollout_a"] = .init(included: true, bucket: 5, percentage: 20)

        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot, evaluator: evaluator)
        try await sut.refresh()

        XCTAssertTrue(sut.isEnabled("rollout_a"))

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlType, .rollout)
        XCTAssertEqual(t.reason, .snapshotEvaluator)
        XCTAssertEqual(t.outcome, .bool(true))
        XCTAssertEqual(t.metadata["bucket"], "5")
        XCTAssertEqual(t.metadata["percentage"], "20")
    }

    // MARK: - Experiment

    func test_variant_missingSnapshot_recordsMissingSnapshot_nil() {
        let tracer = DecisionTracerSpy()
        let repo = RepositoryStub(snapshot: makeSnapshot([]))
        let evaluator = EvaluatorStub()
        let overrides = OverrideStoreStub()

        let sut = DefaultFeatureControlService(
            repository: repo,
            evaluator: evaluator,
            overrideStore: overrides,
            decisionTracer: tracer
        )

        XCTAssertNil(sut.variant(for: "exp_a"))

        let t = try! XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlId, "exp_a")
        XCTAssertEqual(t.controlType, .experiment)
        XCTAssertEqual(t.kind, .variant)
        XCTAssertEqual(t.reason, .missingSnapshot)
        XCTAssertEqual(t.outcome, .variant(nil))
    }

    func test_variant_override_recordsOverride_andOutcomeFromOverride() async throws {
        let snapshot = makeSnapshot([.init(id: "exp_a", type: .experiment, enabled: true, variants: ["A": 50, "B": 50])])
        let overrides = OverrideStoreStub()
        overrides.variantOverrides["exp_a"] = .b

        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot, overrides: overrides)
        try await sut.refresh()

        XCTAssertEqual(sut.variant(for: "exp_a"), .b)

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlType, .experiment)
        XCTAssertEqual(t.kind, .variant)
        XCTAssertEqual(t.reason, .override)
        XCTAssertEqual(t.outcome, .variant(.b))
    }

    func test_variant_invalidConfig_recordsInvalidConfig_nil() async throws {
        let snapshot = makeSnapshot([.init(id: "exp_a", type: .experiment, enabled: true, variants: ["A": 50, "B": 50])])
        let evaluator = EvaluatorStub()
        evaluator.experimentResult["exp_a"] = nil

        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot, evaluator: evaluator)
        try await sut.refresh()

        XCTAssertNil(sut.variant(for: "exp_a"))

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlType, .experiment)
        XCTAssertEqual(t.kind, .variant)
        XCTAssertEqual(t.reason, .invalidConfig)
        XCTAssertEqual(t.outcome, .variant(nil))
    }

    func test_variant_snapshotEvaluator_recordsMetadata_bucket_threshold_weights() async throws {
        let snapshot = makeSnapshot([.init(id: "exp_a", type: .experiment, enabled: true, variants: ["A": 50, "B": 50])])

        let evaluator = EvaluatorStub()
        evaluator.experimentResult["exp_a"] = .init(
            variant: .a,
            bucket: 10,
            weights: ["A": 50, "B": 50],
            thresholdA: 50,
            totalWeight: 100
        )

        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot, evaluator: evaluator)
        try await sut.refresh()

        XCTAssertEqual(sut.variant(for: "exp_a"), .a)

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlType, .experiment)
        XCTAssertEqual(t.kind, .variant)
        XCTAssertEqual(t.reason, .snapshotEvaluator)
        XCTAssertEqual(t.outcome, .variant(.a))
        XCTAssertEqual(t.metadata["bucket"], "10")
        XCTAssertEqual(t.metadata["thresholdA"], "50")
        XCTAssertEqual(t.metadata["totalWeight"], "100")
        XCTAssertNil(t.metadata["weights"])
    }

    // MARK: - Throttle

    func test_throttle_missingSnapshot_recordsMissingSnapshot_nil() {
        let tracer = DecisionTracerSpy()
        let repo = RepositoryStub(snapshot: makeSnapshot([]))
        let evaluator = EvaluatorStub()
        let overrides = OverrideStoreStub()

        let sut = DefaultFeatureControlService(
            repository: repo,
            evaluator: evaluator,
            overrideStore: overrides,
            decisionTracer: tracer
        )

        XCTAssertNil(sut.throttleConfig(for: "throttle_a"))

        let t = try! XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlId, "throttle_a")
        XCTAssertEqual(t.controlType, .throttle)
        XCTAssertEqual(t.kind, .throttle)
        XCTAssertEqual(t.reason, .missingSnapshot)
        XCTAssertEqual(t.outcome, .throttle(nil))
    }

    func test_throttle_override_recordsOverride_andMetadataMaxPerMinute() async throws {
        let snapshot = makeSnapshot([.init(id: "throttle_a", type: .throttle, enabled: true, maxPerMinute: 3)])
        let overrides = OverrideStoreStub()
        overrides.throttleOverrides["throttle_a"] = .init(maxPerMinute: 99)

        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot, overrides: overrides)
        try await sut.refresh()

        XCTAssertEqual(sut.throttleConfig(for: "throttle_a")?.maxPerMinute, 99)

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlType, .throttle)
        XCTAssertEqual(t.kind, .throttle)
        XCTAssertEqual(t.reason, .override)
        XCTAssertEqual(t.outcome, .throttle(.init(maxPerMinute: 99)))
        XCTAssertEqual(t.metadata["maxPerMinute"], "99")
    }

    func test_throttle_invalidConfig_recordsInvalidConfig_nil() async throws {
        let snapshot = makeSnapshot([.init(id: "throttle_a", type: .throttle, enabled: true, maxPerMinute: 3)])
        let evaluator = EvaluatorStub()
        evaluator.throttleResult["throttle_a"] = nil

        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot, evaluator: evaluator)
        try await sut.refresh()

        XCTAssertNil(sut.throttleConfig(for: "throttle_a"))

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlType, .throttle)
        XCTAssertEqual(t.kind, .throttle)
        XCTAssertEqual(t.reason, .invalidConfig)
        XCTAssertEqual(t.outcome, .throttle(nil))
    }

    func test_throttle_snapshotEvaluator_recordsSnapshotEvaluator_andMetadata() async throws {
        let snapshot = makeSnapshot([.init(id: "throttle_a", type: .throttle, enabled: true, maxPerMinute: 3)])
        let evaluator = EvaluatorStub()
        evaluator.throttleResult["throttle_a"] = .init(maxPerMinute: 3)

        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot, evaluator: evaluator)
        try await sut.refresh()

        XCTAssertEqual(sut.throttleConfig(for: "throttle_a")?.maxPerMinute, 3)

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlType, .throttle)
        XCTAssertEqual(t.kind, .throttle)
        XCTAssertEqual(t.reason, .snapshotEvaluator)
        XCTAssertEqual(t.outcome, .throttle(.init(maxPerMinute: 3)))
        XCTAssertEqual(t.metadata["maxPerMinute"], "3")
    }

    func test_variant_missingControl_recordsMissingControl_nil() async throws {
        let snapshot = makeSnapshot([.init(id: "exp_a", type: .experiment, enabled: true, variants: ["A": 50, "B": 50])])
        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot)
        try await sut.refresh()

        XCTAssertNil(sut.variant(for: "exp_missing"))

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlId, "exp_missing")
        XCTAssertEqual(t.kind, .variant)
        XCTAssertEqual(t.reason, .missingControl)
        XCTAssertEqual(t.outcome, .variant(nil))
    }

    func test_throttle_missingControl_recordsMissingControl_nil() async throws {
        let snapshot = makeSnapshot([.init(id: "throttle_a", type: .throttle, enabled: true, maxPerMinute: 3)])
        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot)
        try await sut.refresh()

        XCTAssertNil(sut.throttleConfig(for: "throttle_missing"))

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlId, "throttle_missing")
        XCTAssertEqual(t.kind, .throttle)
        XCTAssertEqual(t.reason, .missingControl)
        XCTAssertEqual(t.outcome, .throttle(nil))
    }

    func test_throttle_wrongType_recordsInvalidConfig_nil() async throws {
        let snapshot = makeSnapshot([.init(id: "throttle_a", type: .flag, enabled: true)])
        let (sut, tracer, _, _) = makeSUT(snapshot: snapshot)
        try await sut.refresh()

        XCTAssertNil(sut.throttleConfig(for: "throttle_a"))

        let t = try XCTUnwrap(tracer.last)
        XCTAssertEqual(t.controlId, "throttle_a")
        XCTAssertEqual(t.kind, .throttle)
        XCTAssertEqual(t.reason, .invalidConfig)
        XCTAssertEqual(t.outcome, .throttle(nil))
        XCTAssertEqual(t.controlType, .flag)
        XCTAssertEqual(t.metadata["error"], "wrong_type")
    }
}
