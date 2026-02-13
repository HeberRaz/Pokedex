//
//  FeatureControlEvaluating.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

protocol FeatureControlEvaluating {
    func isEnabled(flagId: String, snapshot: FeatureControlsSnapshot) -> Bool
    func isIncludedInRollout(rolloutId: String, snapshot: FeatureControlsSnapshot) -> Bool
    func variant(for experimentId: String, snapshot: FeatureControlsSnapshot) -> ExperimentVariant?
    func throttleConfig(for throttleId: String, snapshot: FeatureControlsSnapshot) -> ThrottleConfig?
}
