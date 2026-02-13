//
//  FeatureControlService.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

protocol FeatureControlService {
    func refresh() async throws
    func isEnabled(_ id: String) -> Bool
}

protocol FeatureControlAdvancedService: FeatureControlService {
    func variant(for experimentId: String) -> ExperimentVariant?
    func throttleConfig(for throttleId: String) -> ThrottleConfig?
}
