//
//  DefaultFeatureControlService.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

final class DefaultFeatureControlService: FeatureControlService {

    private let repository: FeatureControlRepository
    private let identityProvider: UserIdentityProvider
    private let bucketer: DeterministicBucketer

    private var snapshot: FeatureControlsSnapshot?

    init(
        repository: FeatureControlRepository,
        identityProvider: UserIdentityProvider,
        bucketer: DeterministicBucketer
    ) {
        self.repository = repository
        self.identityProvider = identityProvider
        self.bucketer = bucketer
    }

    func refresh() async throws {
        snapshot = try await repository.fetchSnapshot()
    }

    func isEnabled(_ id: String) -> Bool {
        guard let control = snapshot?.controls.first(where: { $0.id == id }) else { return false }

        switch control.type {

            case .flag:
                return control.enabled

            case .rollout:
                // Rollout means:
                // - must be enabled
                // - must have percentage [0..100]
                guard (control.enabled),
                      let percentage = control.percentage,
                      (0...100).contains(percentage) else {
                    return false
                }

                // Deterministic decision
                let userId = identityProvider.stableID
                let bucket = bucketer.bucket(for: id, userId: userId)

                // Optional debug for your POC
                print("🧮 rollout id=\(id) user=\(userId.prefix(6)) bucket=\(bucket) pct=\(percentage) -> \(bucket < percentage)")

                return bucket < percentage

            case .experiment:
                // POC: just ON/OFF for now. Later you add variant assignment with weights.
                return control.enabled

            case .throttle:
                // POC placeholder
                return control.enabled
        }
    }
}
