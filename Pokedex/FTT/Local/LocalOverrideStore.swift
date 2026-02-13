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

    func overrideThrottle(for id: String) -> ThrottleConfig?
    func setThrottleOverride(_ value: ThrottleConfig?, for id: String)

    func clear(id: String)
    func clearAll()
}
