//
//  UserDefaultsLocalOverrideStore.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//

import Foundation

final class UserDefaultsLocalOverrideStore: LocalOverrideStore {

    private let userDefaults: UserDefaults
    private let isOverridesEnabled: Bool

    private enum Keys {
        static let prefix = "ftt.override."
        static let boolPrefix = "ftt.override.bool."
        static let variantPrefix = "ftt.override.variant."
        static let throttlePrefix = "ftt.override.throttle."
        static let rolloutPrefix = "ftt.override.rollout."
    }

    init(
        userDefaults: UserDefaults = .standard,
        isOverridesEnabled: Bool = {
#if DEBUG
            return true
#else
            return false
#endif
        }()
    ) {
        self.userDefaults = userDefaults
        self.isOverridesEnabled = isOverridesEnabled
    }

    // MARK: - Bool

    func overrideBool(for id: String) -> Bool? {
        guard isOverridesEnabled else { return nil }
        return userDefaults.object(forKey: Keys.boolPrefix + id) as? Bool
    }

    func setBoolOverride(_ value: Bool?, for id: String) {
        guard isOverridesEnabled else { return }
        let key = Keys.boolPrefix + id
        if let value { userDefaults.set(value, forKey: key) }
        else { userDefaults.removeObject(forKey: key) }
    }

    // MARK: - Variant

    func overrideVariant(for id: String) -> ExperimentVariant? {
        guard isOverridesEnabled else { return nil }
        guard let raw = userDefaults.string(forKey: Keys.variantPrefix + id) else { return nil }
        return ExperimentVariant(rawValue: raw)
    }

    func setVariantOverride(_ value: ExperimentVariant?, for id: String) {
        guard isOverridesEnabled else { return }
        let key = Keys.variantPrefix + id
        if let value { userDefaults.set(value.rawValue, forKey: key) }
        else { userDefaults.removeObject(forKey: key) }
    }

    // MARK: - Rollout percentage

    func overrideRolloutPercentage(for id: String) -> Int? {
        guard isOverridesEnabled else { return nil }
        let key = Keys.rolloutPrefix + id
        let value = userDefaults.object(forKey: key) as? Int
        guard let value, (0...100).contains(value) else { return nil }
        return value
    }

    func setRolloutPercentageOverride(_ value: Int?, for id: String) {
        guard isOverridesEnabled else { return }
        let key = Keys.rolloutPrefix + id
        if let value, (0...100).contains(value) {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }

    // MARK: - Throttle

    func overrideThrottle(for id: String) -> ThrottleConfig? {
        guard isOverridesEnabled else { return nil }
        let key = Keys.throttlePrefix + id
        let raw = userDefaults.integer(forKey: key) // devuelve 0 si no existe
        return raw > 0 ? ThrottleConfig(maxPerMinute: raw) : nil
    }

    func setThrottleOverride(_ value: ThrottleConfig?, for id: String) {
        guard isOverridesEnabled else { return }
        let key = Keys.throttlePrefix + id
        if let value { userDefaults.set(value.maxPerMinute, forKey: key) }
        else { userDefaults.removeObject(forKey: key) }
    }

    // MARK: - Clear (allowed always)

    func clear(id: String) {
        userDefaults.removeObject(forKey: Keys.boolPrefix + id)
        userDefaults.removeObject(forKey: Keys.variantPrefix + id)
        userDefaults.removeObject(forKey: Keys.throttlePrefix + id)
        userDefaults.removeObject(forKey: Keys.rolloutPrefix + id)
    }

    func clearAll() {
        userDefaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(Keys.prefix) }
            .forEach { userDefaults.removeObject(forKey: $0) }
    }
}
