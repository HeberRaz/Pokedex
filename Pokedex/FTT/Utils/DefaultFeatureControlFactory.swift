//
//  DefaultFeatureControlFactory.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

final class DefaultFeatureControlFactory: FeatureControlFactory {
    func makeService() -> FeatureControlService {

        let repository = LocalFeatureControlRepository(
            source: .bundle(name: "feature_controls", ext: "json", bundle: .main)
        )

        let identity = DefaultUserIdentityProvider(userDefaults: .standard)
        let bucketer = SHA256DeterministicBucketer()

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: identity,
            bucketer: bucketer
        )

        return DefaultFeatureControlService(
            repository: repository,
            evaluator: evaluator
        )
    }
}
