//
//  DefaultFeatureControlEvaluator.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

final class DefaultFeatureControlEvaluator: FeatureControlEvaluating {

    private let identityProvider: UserIdentityProvider
    private let bucketer: DeterministicBucketer

    init(identityProvider: UserIdentityProvider, bucketer: DeterministicBucketer) {
        self.identityProvider = identityProvider
        self.bucketer = bucketer
    }

    func isEnabled(flagId: String, snapshot: FeatureControlsSnapshot) -> Bool {
        guard let c = snapshot.controls.first(where: { $0.id == flagId && $0.type == .flag }) else { return false }
        return c.enabled
    }

    func isIncludedInRollout(rolloutId: String, snapshot: FeatureControlsSnapshot) -> Bool {
        guard let c = snapshot.controls.first(where: { $0.id == rolloutId && $0.type == .rollout }) else { return false }
        guard c.enabled, let pct = c.percentage, (0...100).contains(pct) else { return false }

        let userId = identityProvider.stableID
        let bucket = bucketer.bucket(for: rolloutId, userId: userId)

        // opcional: observabilidad POC
        print("🧮 rollout id=\(rolloutId) user=\(userId.prefix(6)) bucket=\(bucket) pct=\(pct) -> \(bucket < pct)")

        return bucket < pct
    }

    func variant(for experimentId: String, snapshot: FeatureControlsSnapshot) -> ExperimentVariant? {
        guard let c = snapshot.controls.first(where: { $0.id == experimentId && $0.type == .experiment }) else { return nil }
        guard c.enabled, let variants = c.variants, !variants.isEmpty else { return nil }

        // POC: soporta A/B (A y B) con pesos que suman 100 (idealmente)
        let weightA = variants["A"] ?? 0
        let weightB = variants["B"] ?? 0
        let total = weightA + weightB
        guard total > 0 else { return nil }

        let userId = identityProvider.stableID
        let bucket = bucketer.bucket(for: experimentId, userId: userId) // 0..99

        // normaliza pesos a 0..99 aunque no sumen 100
        let normalizedA = Int(((Double(weightA) / Double(total)) * 100.0).rounded())
        let threshold = min(max(normalizedA, 0), 100)
        return bucket < threshold ? .a : .b
    }

    func throttleConfig(for throttleId: String, snapshot: FeatureControlsSnapshot) -> ThrottleConfig? {
        guard let c = snapshot.controls.first(where: { $0.id == throttleId && $0.type == .throttle }) else { return nil }
        guard c.enabled, let max = c.maxPerMinute else { return nil }
        return ThrottleConfig(maxPerMinute: max)
    }
}
