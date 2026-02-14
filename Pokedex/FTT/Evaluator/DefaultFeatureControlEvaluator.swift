//
//  DefaultFeatureControlEvaluator.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

// MARK: - Evaluator

final class DefaultFeatureControlEvaluator: FeatureControlEvaluating {

    private let identityProvider: UserIdentityProvider
    private let bucketer: DeterministicBucketer

    init(identityProvider: UserIdentityProvider, bucketer: DeterministicBucketer) {
        self.identityProvider = identityProvider
        self.bucketer = bucketer
    }

    // MARK: - Flag

    func isEnabled(flagId: String, snapshot: FeatureControlsSnapshot) -> Bool {
        guard let control = snapshot.controls.first(where: { $0.id == flagId && $0.type == .flag }) else { return false }
        return control.enabled
    }

    // MARK: - Rollout (returns metadata for DecisionTrace)

    func evaluateRollout(rolloutId: String, snapshot: FeatureControlsSnapshot) -> RolloutEvaluationResult? {
        guard let control = snapshot.controls.first(where: { $0.id == rolloutId && $0.type == .rollout }) else { return nil }
        guard control.enabled, let pct = control.percentage, (0...100).contains(pct) else { return nil }

        let userId = identityProvider.stableID
        let bucket = bucketer.bucket(for: rolloutId, userId: userId)
        let included = bucket < pct

        return RolloutEvaluationResult(
            included: included,
            bucket: bucket,
            percentage: pct
        )
    }

    // MARK: - Experiment (returns metadata for DecisionTrace)

    func evaluateExperiment(experimentId: String, snapshot: FeatureControlsSnapshot) -> ExperimentEvaluationResult? {
        guard let control = snapshot.controls.first(where: { $0.id == experimentId && $0.type == .experiment }) else { return nil }
        guard control.enabled, let variants = control.variants, !variants.isEmpty else { return nil }

        // POC: A/B with weights
        let weightA = variants["A"] ?? 0
        let weightB = variants["B"] ?? 0
        let total = weightA + weightB
        guard total > 0 else { return nil }

        let userId = identityProvider.stableID
        let bucket = bucketer.bucket(for: experimentId, userId: userId) // 0..99

        // Normalize even if weights don't sum to 100
        let normalizedA = Int(((Double(weightA) / Double(total)) * 100.0).rounded())
        let thresholdA = min(max(normalizedA, 0), 100)

        let variant: ExperimentVariant = bucket < thresholdA ? .a : .b

        return ExperimentEvaluationResult(
            variant: variant,
            bucket: bucket,
            weights: variants,
            thresholdA: thresholdA,
            totalWeight: total
        )
    }

    // MARK: - Throttle

    func throttleConfig(for throttleId: String, snapshot: FeatureControlsSnapshot) -> ThrottleConfig? {
        guard let control = snapshot.controls.first(where: { $0.id == throttleId && $0.type == .throttle }) else { return nil }
        guard control.enabled, let max = control.maxPerMinute else { return nil }
        return ThrottleConfig(maxPerMinute: max)
    }
}
