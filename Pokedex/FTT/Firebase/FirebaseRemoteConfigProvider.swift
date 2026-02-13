//
//  FirebaseRemoteConfigProvider.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//


import FirebaseRemoteConfig

final class FirebaseRemoteConfigProvider: RemoteConfigProviding {

    private let remoteConfig: RemoteConfig

    init(remoteConfig: RemoteConfig = .remoteConfig(),
         minimumFetchInterval: TimeInterval = 3600) {
        self.remoteConfig = remoteConfig

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = minimumFetchInterval
        settings.fetchTimeout = 10
        remoteConfig.configSettings = settings
    }

    func fetchAndActivate() async throws {
        try await remoteConfig.fetchAndActivate()
    }

    func string(forKey key: String) -> String? {
        remoteConfig.configValue(forKey: key).stringValue
    }

    func source(forKey key: String) -> RemoteConfigValueSource {
        switch remoteConfig.configValue(forKey: key).source {
            case .remote: return .remote
            case .default: return .default
            case .static: return .static
            @unknown default: return .unknown
        }
    }
}
