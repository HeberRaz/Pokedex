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
    private var snapshot: FeatureControlsSnapshot?

    init(repository: FeatureControlRepository, evaluator: FeatureControlEvaluating) {
        self.repository = repository
        self.evaluator = evaluator
    }

    func refresh() async throws {
        snapshot = try await repository.fetchSnapshot()
    }

    func isEnabled(_ id: String) -> Bool {
        guard let snap = snapshot else { return false }
        guard let c = snap.controls.first(where: { $0.id == id }) else { return false }

        switch c.type {
            case .flag:
                return evaluator.isEnabled(flagId: id, snapshot: snap)
            case .rollout:
                return evaluator.isIncludedInRollout(rolloutId: id, snapshot: snap)
            case .experiment:
                return evaluator.variant(for: id, snapshot: snap) != nil // o decide que “enabled” significa “tiene variante”
            case .throttle:
                return evaluator.throttleConfig(for: id, snapshot: snap) != nil
        }
    }
}
