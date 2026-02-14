//
//  LocalOverrideStore.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//

import Foundation

protocol LocalOverrideStore {
    func overrideBool(for id: String) -> Bool?
    func setBoolOverride(_ value: Bool?, for id: String)

    func overrideVariant(for id: String) -> ExperimentVariant?
    func setVariantOverride(_ value: ExperimentVariant?, for id: String)

    /// Rollout percentage override (0...100). When present, it replaces the
    /// remote percentage for evaluation, but the underlying control must
    /// still be enabled.
    func overrideRolloutPercentage(for id: String) -> Int?
    func setRolloutPercentageOverride(_ value: Int?, for id: String)

    func overrideThrottle(for id: String) -> ThrottleConfig?
    func setThrottleOverride(_ value: ThrottleConfig?, for id: String)

    func clear(id: String)
    func clearAll()
}
