//
//  EvaluatorStub.swift
//  PokedexTests
//
//  Created by Heber Alvarez on 13/02/26.
//

@testable import Pokedex

final class EvaluatorStub: FeatureControlEvaluating {
    var flagValue: [String: Bool] = [:]
    var rolloutResult: [String: RolloutEvaluationResult?] = [:]
    var experimentResult: [String: ExperimentEvaluationResult?] = [:]
    var throttleResult: [String: ThrottleConfig?] = [:]

    func isEnabled(flagId: String, snapshot: FeatureControlsSnapshot) -> Bool {
        flagValue[flagId] ?? false
    }

    func evaluateRollout(rolloutId: String, snapshot: FeatureControlsSnapshot) -> RolloutEvaluationResult? {
        rolloutResult[rolloutId] ?? nil
    }

    func evaluateExperiment(experimentId: String, snapshot: FeatureControlsSnapshot) -> ExperimentEvaluationResult? {
        experimentResult[experimentId] ?? nil
    }

    func throttleConfig(for throttleId: String, snapshot: FeatureControlsSnapshot) -> ThrottleConfig? {
        throttleResult[throttleId] ?? nil
    }
    }
