//
//  FeatureControlClient.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//

import Foundation

protocol FeatureControlClient {
    func refresh() async throws

    // Capability 1: Bool facade
    func isEnabled(_ id: String) -> Bool

    // Capability 2: Experiments
    func variant(for experimentId: String) -> ExperimentVariant?

    // Capability 3: Throttling
    func throttleConfig(for throttleId: String) -> ThrottleConfig?
}
