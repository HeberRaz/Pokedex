//
//  DefaultFeatureControlFactory.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

final class DefaultFeatureControlFactory: FeatureControlFactory {

    func makeClient() -> FeatureControlClient {
        DefaultFeatureControlClient(service: makeService())
    }

    private func makeService() -> FeatureControlAdvancedService {

        // Local baseline (siempre disponible)
        let localRepository = LocalFeatureControlRepository(
            source: .bundle(name: "feature_controls", ext: "json", bundle: .main)
        )

        // Remote (Firebase)
        let remoteProvider = FirebaseRemoteConfigProvider(
            minimumFetchInterval: {
#if DEBUG
                return 0
#else
                return 3600
#endif
            }()
        )

        let firebaseRepository = FirebaseFeatureControlRepository(
            remoteConfig: remoteProvider,
            key: "ftt_snapshot_json",
            policy: .acceptRemoteOrDefault
        )

        // Fallback chain: remote -> local
        let repository: FeatureControlRepository = FallbackFeatureControlRepository(
            primary: firebaseRepository,
            fallback: localRepository)

        let identity = DefaultUserIdentityProvider(userDefaults: .standard)
        let bucketer = SHA256DeterministicBucketer()

        let evaluator = DefaultFeatureControlEvaluator(
            identityProvider: identity,
            bucketer: bucketer
        )

        let overrideStore = UserDefaultsLocalOverrideStore()

        let tracer: DecisionTracing = {
#if DEBUG
            return LoggerDecisionTracer()
#else
            return NoopDecisionTracer()
#endif
        }()

        return DefaultFeatureControlService(
            repository: repository,
            evaluator: evaluator,
            overrideStore: overrideStore,
            decisionTracer: tracer
        )
    }
}
