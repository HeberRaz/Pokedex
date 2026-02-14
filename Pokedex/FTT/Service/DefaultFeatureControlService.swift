//
//  DefaultFeatureControlService.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

final class DefaultFeatureControlService: FeatureControlService {

    private let repository: FeatureControlRepository
    private let evaluator: FeatureControlEvaluating
    private let overrideStore: LocalOverrideStore
    private let decisionTracer: DecisionTracing
    private let snapshotStore: FeatureControlsSnapshotStore?
    private let minimumRefreshInterval: TimeInterval

    private let queue = DispatchQueue(label: "com.heber.Pokedex.featureControlService")
    private var snapshot: FeatureControlsSnapshot?
    private var lastRefreshDate: Date?

    init(
        repository: FeatureControlRepository,
        evaluator: FeatureControlEvaluating,
        overrideStore: LocalOverrideStore,
        decisionTracer: DecisionTracing = NoopDecisionTracer(),
        snapshotStore: FeatureControlsSnapshotStore? = nil,
        minimumRefreshInterval: TimeInterval = 60
    ) {
        self.repository = repository
        self.evaluator = evaluator
        self.overrideStore = overrideStore
        self.decisionTracer = decisionTracer
        self.snapshotStore = snapshotStore
        self.minimumRefreshInterval = minimumRefreshInterval

        // Best-effort load of last known-good snapshot from disk.
        if let snapshotStore {
            if let cached = try? snapshotStore.load() {
                self.snapshot = cached
            }
        }
    }

    func refresh() async throws {
        let now = Date()

        // Avoid hammering the repository if we recently refreshed successfully.
        let (currentSnapshot, lastRefresh) = queue.sync { (snapshot, lastRefreshDate) }
        if currentSnapshot != nil,
           let lastRefresh,
           now.timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            return
        }

        do {
            let newSnapshot = try await repository.fetchSnapshot()

            queue.sync {
                self.snapshot = newSnapshot
                self.lastRefreshDate = now
            }

            // Persist last known-good snapshot. Errors here should not break callers.
            try? snapshotStore?.save(newSnapshot)
        } catch {
            let existingSnapshot = queue.sync { snapshot }

            // Try to recover from store first.
            if let snapshotStore, let cached = try? snapshotStore.load() {
                queue.sync {
                    self.snapshot = cached
                    self.lastRefreshDate = nil
                }
                return
            }

            // If we already had an in-memory snapshot, keep using it and do not fail hard.
            if existingSnapshot != nil {
                return
            }

            // No snapshot anywhere, propagate the failure.
            throw error
        }
    }

    func isEnabled(_ id: String) -> Bool {
        let snap = queue.sync { snapshot }

        guard let snap else {
            decisionTracer.record(.init(
                controlId: id,
                controlType: nil,
                kind: .bool,
                outcome: .bool(false),
                reason: .missingSnapshot
            ))
            return false
        }

        guard let control = snap.controls.first(where: { $0.id == id }) else {
            decisionTracer.record(.init(
                controlId: id,
                controlType: nil,
                kind: .bool,
                outcome: .bool(false),
                reason: .missingControl
            ))
            return false
        }

        switch control.type {

            case .flag:
                if let override = overrideStore.overrideBool(for: id) {
                    decisionTracer.record(.init(
                        controlId: id,
                        controlType: control.type,
                        kind: .bool,
                        outcome: .bool(override),
                        reason: .override
                    ))
                    return override
                }

                let value = evaluator.isEnabled(flagId: id, snapshot: snap)
                decisionTracer.record(.init(
                    controlId: id,
                    controlType: control.type,
                    kind: .bool,
                    outcome: .bool(value),
                    reason: .snapshotEvaluator
                ))
                return value

            case .rollout:
                if let override = overrideStore.overrideBool(for: id) {
                    decisionTracer.record(.init(
                        controlId: id,
                        controlType: control.type,
                        kind: .bool,
                        outcome: .bool(override),
                        reason: .override
                    ))
                    return override
                }

                guard let result = evaluator.evaluateRollout(rolloutId: id, snapshot: snap) else {
                    decisionTracer.record(.init(
                        controlId: id,
                        controlType: control.type,
                        kind: .bool,
                        outcome: .bool(false),
                        reason: .invalidConfig
                    ))
                    return false
                }

                let pctOverride = overrideStore.overrideRolloutPercentage(for: id)
                let effectivePercentage = pctOverride ?? result.percentage
                let included = result.bucket < effectivePercentage

                var metadata: [String: String] = [
                    "bucket": "\(result.bucket)",
                    "percentage": "\(result.percentage)",
                    "effectivePercentage": "\(effectivePercentage)",
                    "percentageSource": (pctOverride != nil ? "override" : "remote")
                ]

                decisionTracer.record(.init(
                    controlId: id,
                    controlType: control.type,
                    kind: .bool,
                    outcome: .bool(included),
                    reason: (pctOverride != nil ? .override : .snapshotEvaluator),
                    metadata: metadata
                ))
                return included

            case .experiment:
                return variant(for: id) != nil

            case .throttle:
                return throttleConfig(for: id) != nil
        }
    }
}

extension DefaultFeatureControlService: FeatureControlAdvancedService {

    func controlsCount() -> Int {
        let snap = queue.sync { snapshot }
        return snap?.controls.count ?? 0
    }

    func variant(for experimentId: String) -> ExperimentVariant? {
        let snap = queue.sync { snapshot }

        guard let snap else {
            decisionTracer.record(.init(
                controlId: experimentId,
                controlType: .experiment,
                kind: .variant,
                outcome: .variant(nil),
                reason: .missingSnapshot
            ))
            return nil
        }

        // ✅ NUEVO: distinguir missingControl
        guard let control = snap.controls.first(where: { $0.id == experimentId }) else {
            decisionTracer.record(.init(
                controlId: experimentId,
                controlType: nil,
                kind: .variant,
                outcome: .variant(nil),
                reason: .missingControl
            ))
            return nil
        }

        // ✅ NUEVO: validar type (si existe pero es otro tipo)
        guard control.type == .experiment else {
            decisionTracer.record(.init(
                controlId: experimentId,
                controlType: control.type,
                kind: .variant,
                outcome: .variant(nil),
                reason: .invalidConfig,
                metadata: ["error": "wrong_type"]
            ))
            return nil
        }

        if let override = overrideStore.overrideVariant(for: experimentId) {
            decisionTracer.record(.init(
                controlId: experimentId,
                controlType: .experiment,
                kind: .variant,
                outcome: .variant(override),
                reason: .override
            ))
            return override
        }

        guard let result = evaluator.evaluateExperiment(experimentId: experimentId, snapshot: snap) else {
            decisionTracer.record(.init(
                controlId: experimentId,
                controlType: .experiment,
                kind: .variant,
                outcome: .variant(nil),
                reason: .invalidConfig
            ))
            return nil
        }

        // ✅ MEJORA: metadata estable (ver punto 2)
        var meta: [String: String] = [
            "bucket": "\(result.bucket)",
            "thresholdA": "\(result.thresholdA)",
            "totalWeight": "\(result.totalWeight)"
        ]
        meta.merge(stableWeightsMetadata(result.weights), uniquingKeysWith: { $1 })

        decisionTracer.record(.init(
            controlId: experimentId,
            controlType: .experiment,
            kind: .variant,
            outcome: .variant(result.variant),
            reason: .snapshotEvaluator,
            metadata: meta
        ))

        return result.variant
    }

    func throttleConfig(for throttleId: String) -> ThrottleConfig? {
        let snap = queue.sync { snapshot }

        guard let snap else {
            decisionTracer.record(.init(
                controlId: throttleId,
                controlType: .throttle,
                kind: .throttle,
                outcome: .throttle(nil),
                reason: .missingSnapshot
            ))
            return nil
        }

        // ✅ NUEVO: missingControl
        guard let control = snap.controls.first(where: { $0.id == throttleId }) else {
            decisionTracer.record(.init(
                controlId: throttleId,
                controlType: nil,
                kind: .throttle,
                outcome: .throttle(nil),
                reason: .missingControl
            ))
            return nil
        }

        // ✅ NUEVO: validar type
        guard control.type == .throttle else {
            decisionTracer.record(.init(
                controlId: throttleId,
                controlType: control.type,
                kind: .throttle,
                outcome: .throttle(nil),
                reason: .invalidConfig,
                metadata: ["error": "wrong_type"]
            ))
            return nil
        }

        if let override = overrideStore.overrideThrottle(for: throttleId) {
            decisionTracer.record(.init(
                controlId: throttleId,
                controlType: .throttle,
                kind: .throttle,
                outcome: .throttle(override),
                reason: .override,
                metadata: ["maxPerMinute": "\(override.maxPerMinute)"]
            ))
            return override
        }

        let config = evaluator.throttleConfig(for: throttleId, snapshot: snap)

        if let config {
            decisionTracer.record(.init(
                controlId: throttleId,
                controlType: .throttle,
                kind: .throttle,
                outcome: .throttle(config),
                reason: .snapshotEvaluator,
                metadata: ["maxPerMinute": "\(config.maxPerMinute)"]
            ))
        } else {
            decisionTracer.record(.init(
                controlId: throttleId,
                controlType: .throttle,
                kind: .throttle,
                outcome: .throttle(nil),
                reason: .invalidConfig
            ))
        }

        return config
    }

    private func stableWeightsMetadata(_ weights: [String: Int]) -> [String: String] {
        // stable + grep-friendly
        // weights.A=50 weights.B=50
        var meta: [String: String] = [:]
        for key in weights.keys.sorted() {
            meta["weights.\(key)"] = "\(weights[key] ?? 0)"
        }
        return meta
    }
}
