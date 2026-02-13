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

    private var snapshot: FeatureControlsSnapshot?

    init(
        repository: FeatureControlRepository,
        evaluator: FeatureControlEvaluating,
        overrideStore: LocalOverrideStore,
        decisionTracer: DecisionTracing = NoopDecisionTracer()
    ) {
        self.repository = repository
        self.evaluator = evaluator
        self.overrideStore = overrideStore
        self.decisionTracer = decisionTracer
    }

    func refresh() async throws {
        snapshot = try await repository.fetchSnapshot()
    }

    func isEnabled(_ id: String) -> Bool {
        guard let snap = snapshot else {
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
                if let o = overrideStore.overrideBool(for: id) {
                    decisionTracer.record(.init(
                        controlId: id,
                        controlType: control.type,
                        kind: .bool,
                        outcome: .bool(o),
                        reason: .override
                    ))
                    return o
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
                if let o = overrideStore.overrideBool(for: id) {
                    decisionTracer.record(.init(
                        controlId: id,
                        controlType: control.type,
                        kind: .bool,
                        outcome: .bool(o),
                        reason: .override
                    ))
                    return o
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

                decisionTracer.record(.init(
                    controlId: id,
                    controlType: control.type,
                    kind: .bool,
                    outcome: .bool(result.included),
                    reason: .snapshotEvaluator,
                    metadata: [
                        "bucket": "\(result.bucket)",
                        "percentage": "\(result.percentage)"
                    ]
                ))
                return result.included

            case .experiment:
                return variant(for: id) != nil

            case .throttle:
                return throttleConfig(for: id) != nil
        }
    }
}

extension DefaultFeatureControlService: FeatureControlAdvancedService {

    func variant(for experimentId: String) -> ExperimentVariant? {
        guard let snap = snapshot else {
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

        if let o = overrideStore.overrideVariant(for: experimentId) {
            decisionTracer.record(.init(
                controlId: experimentId,
                controlType: .experiment,
                kind: .variant,
                outcome: .variant(o),
                reason: .override
            ))
            return o
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
        guard let snap = snapshot else {
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

        if let o = overrideStore.overrideThrottle(for: throttleId) {
            decisionTracer.record(.init(
                controlId: throttleId,
                controlType: .throttle,
                kind: .throttle,
                outcome: .throttle(o),
                reason: .override,
                metadata: ["maxPerMinute": "\(o.maxPerMinute)"]
            ))
            return o
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
