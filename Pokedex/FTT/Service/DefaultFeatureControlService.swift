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
    private var snapshot: FeatureControlsSnapshot?

    init(
        repository: FeatureControlRepository,
        evaluator: FeatureControlEvaluating,
        overrideStore: LocalOverrideStore
    ) {
        self.repository = repository
        self.evaluator = evaluator
        self.overrideStore = overrideStore
    }

    func refresh() async throws {
        snapshot = try await repository.fetchSnapshot()
    }

    // MARK: - Bool facade
    func isEnabled(_ id: String) -> Bool {
        guard let snap = snapshot else { return false }
        guard let control = snap.controls.first(where: { $0.id == id }) else { return false }

        switch control.type {

            case .flag:
                return resolve(
                    override: overrideStore.overrideBool(for: id),
                    fallback: evaluator.isEnabled(flagId: id, snapshot: snap)
                )

            case .rollout:
                return resolve(
                    override: overrideStore.overrideBool(for: id),
                    fallback: evaluator.isIncludedInRollout(rolloutId: id, snapshot: snap)
                )

            case .experiment:
                // "enabled" = has assigned variant (via override or evaluator)
                return variant(for: id) != nil

            case .throttle:
                // "enabled" = has config (via override or evaluator)
                return throttleConfig(for: id) != nil
        }
    }

    private func resolve<T>(
        override: @autoclosure () -> T?,
        fallback: @autoclosure () -> T
    ) -> T {
        if let value = override() { return value }
        return fallback()
    }
}

extension DefaultFeatureControlService: FeatureControlAdvancedService {
    // MARK: - Experiment
    func variant(for experimentId: String) -> ExperimentVariant? {
        guard let snap = snapshot else { return nil }
        // override wins
        if let override = overrideStore.overrideVariant(for: experimentId) {
            return override
        }
        return evaluator.variant(for: experimentId, snapshot: snap)
    }

    // MARK: - Throttle
    func throttleConfig(for throttleId: String) -> ThrottleConfig? {
        guard let snap = snapshot else { return nil }
        // override wins
        if let override = overrideStore.overrideThrottle(for: throttleId) {
            return override
        }
        return evaluator.throttleConfig(for: throttleId, snapshot: snap)
    }
}
