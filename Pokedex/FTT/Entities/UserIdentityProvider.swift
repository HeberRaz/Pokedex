//
//  UserIdentityProvider.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation
/// Provides a stable identifier used for deterministic rollouts/experiments.
///
/// MARK: - POC NOTE
/// For the POC we persist this ID in UserDefaults because:
/// - We only need stability across app launches to prove deterministic rollout behavior.
/// - We are validating architecture + hashing consistency, not security or reinstall persistence.
///
/// What we are intentionally NOT doing yet (Production hardening):
/// - Storing in Keychain to survive reinstalls and reduce easy tampering.
/// - Using a server-provided userId when logged-in (best option for cross-device consistency).
/// - Using Firebase Installation ID / AppInstanceId (if applicable), which ties to Firebase configuration.
///
/// The important part is the API contract:
/// `stableID` must be stable and available synchronously.
protocol UserIdentityProvider {
    var stableID: String { get }
}
