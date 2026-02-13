//
//  DefaultUserIdentityProvider.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

/// Default POC identity provider: stable UUID persisted in UserDefaults.
final class DefaultUserIdentityProvider: UserIdentityProvider {

    private enum Keys {
        static let stableID = "feature_control.stable_id"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // ⚠️ Here we are using UserDefaults due to the POC. It is important to use a REAL stable Id.
    // Do we have it? does it persist across new installations?
    // Investigate further.
    var stableID: String {
        if let existing = userDefaults.string(forKey: Keys.stableID), !existing.isEmpty {
            return existing
        }

        let newID = UUID().uuidString
        userDefaults.set(newID, forKey: Keys.stableID)
        return newID
    }
}
