//
//  OverrideStoreStub.swift
//  PokedexTests
//
//  Created by Heber Alvarez on 13/02/26.
//

@testable import Pokedex

final class OverrideStoreStub: LocalOverrideStore {
    var boolOverrides: [String: Bool] = [:]
    var variantOverrides: [String: ExperimentVariant] = [:]
    var throttleOverrides: [String: ThrottleConfig] = [:]

    // MARK: - Getters

    func overrideBool(for id: String) -> Bool? {
        boolOverrides[id]
    }

    func overrideVariant(for id: String) -> ExperimentVariant? {
        variantOverrides[id]
    }

    func overrideThrottle(for id: String) -> ThrottleConfig? {
        throttleOverrides[id]
    }

    // MARK: - Setters

    func setBoolOverride(_ value: Bool?, for id: String) {
        if let value {
            boolOverrides[id] = value
        } else {
            boolOverrides.removeValue(forKey: id)
        }
    }

    func setVariantOverride(_ value: ExperimentVariant?, for id: String) {
        if let value {
            variantOverrides[id] = value
        } else {
            variantOverrides.removeValue(forKey: id)
        }
    }

    func setThrottleOverride(_ value: ThrottleConfig?, for id: String) {
        if let value {
            throttleOverrides[id] = value
        } else {
            throttleOverrides.removeValue(forKey: id)
        }
    }

    // MARK: - Clear

    func clear(id: String) {
        boolOverrides.removeValue(forKey: id)
        variantOverrides.removeValue(forKey: id)
        throttleOverrides.removeValue(forKey: id)
    }

    func clearAll() {
        boolOverrides.removeAll()
        variantOverrides.removeAll()
        throttleOverrides.removeAll()
    }
}
