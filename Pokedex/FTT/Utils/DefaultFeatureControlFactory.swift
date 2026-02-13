//
//  DefaultFeatureControlFactory.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

final class DefaultFeatureControlFactory: FeatureControlFactory {
    func makeService() -> FeatureControlService {
        DefaultFeatureControlService(
            repository: LocalFeatureControlRepository(
                source: .bundle(name: "feature_controls", ext: "json", bundle: .main)
            ),
            identityProvider: DefaultUserIdentityProvider(userDefaults: .standard), // POC
            bucketer: SHA256DeterministicBucketer()
        )
    }
}
