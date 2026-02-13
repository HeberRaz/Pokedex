//
//  FirebaseFeatureControlRepository.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//

import Foundation

final class FirebaseFeatureControlRepository: FeatureControlRepository {
    private let remoteConfig: RemoteConfigProviding
    private let decoder: JSONDecoder
    private let key: String
    private let policy: RemoteConfigValuePolicy

    init(
        remoteConfig: RemoteConfigProviding,
        decoder: JSONDecoder = JSONDecoder(),
        key: String = "ftt_snapshot_json",
        policy: RemoteConfigValuePolicy = .acceptRemoteOrDefault
    ) {
        self.remoteConfig = remoteConfig
        self.decoder = decoder
        self.key = key
        self.policy = policy
    }

    func fetchSnapshot() async throws -> FeatureControlsSnapshot {
        try await remoteConfig.fetchAndActivate()

        let source = remoteConfig.source(forKey: key)

        switch policy {
            case .acceptRemoteOnly:
                guard source == .remote else {
                    throw FeatureControlRepoError.missingKey(key: key) // o crea .notRemote(...)
                }
            case .acceptRemoteOrDefault:
                guard source == .remote || source == .default else {
                    throw FeatureControlRepoError.missingKey(key: key)
                }
        }

        guard let json = remoteConfig.string(forKey: key),
              !json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FeatureControlRepoError.emptyJSON(key: key)
        }

        guard let data = json.data(using: .utf8) else {
            throw FeatureControlRepoError.invalidUTF8(key: key)
        }

        do {
            return try decoder.decode(FeatureControlsSnapshot.self, from: data)
        } catch {
            throw FeatureControlRepoError.decodingFailed(
                key: key,
                underlyingDescription: String(describing: error)
            )
        }
    }
}
