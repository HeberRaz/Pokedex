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

        let notificationTracer = NotificationCenterDecisionTracer()

        let loggerTracer: DecisionTracing = LoggerDecisionTracer()

        let sampledLogger: DecisionTracing = {
    #if DEBUG
            // In debug we want full fidelity for troubleshooting.
            return loggerTracer
    #else
            // In production, keep logs lightweight with sampling.
            return SamplingDecisionTracer(base: loggerTracer, sampleRate: 1)
    #endif
        }()

        let tracer: DecisionTracing = CompositeDecisionTracer([
            sampledLogger,
            notificationTracer
        ])

        let snapshotStore = FileFeatureControlsSnapshotStore()

        return DefaultFeatureControlService(
            repository: repository,
            evaluator: evaluator,
            overrideStore: overrideStore,
            decisionTracer: tracer,
            snapshotStore: snapshotStore,
            minimumRefreshInterval: {
#if DEBUG
                return 5 // fast iterations while developing
#else
                return 60 // seconds between remote refresh attempts
#endif
            }()
        )
    }
}
