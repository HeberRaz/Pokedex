//
//  FeatureControlEvaluating.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

protocol FeatureControlEvaluating {
    func isEnabled(flagId: String, snapshot: FeatureControlsSnapshot) -> Bool
    func evaluateRollout(rolloutId: String, snapshot: FeatureControlsSnapshot) -> RolloutEvaluationResult?
    func evaluateExperiment(experimentId: String, snapshot: FeatureControlsSnapshot) -> ExperimentEvaluationResult?
    func throttleConfig(for throttleId: String, snapshot: FeatureControlsSnapshot) -> ThrottleConfig?
}
