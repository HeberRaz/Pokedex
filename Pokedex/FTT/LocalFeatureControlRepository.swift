//
//  LocalFeatureControlRepository.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

public enum LocalFeatureControlSource: Sendable {
    case bundle(name: String, ext: String = "json", bundle: Bundle = .main)
    case inMemory(json: String)
}

public final class LocalFeatureControlRepository: FeatureControlRepository {
    private let source: LocalFeatureControlSource

    public init(source: LocalFeatureControlSource) {
        self.source = source
    }

    public func fetchSnapshot() async throws -> FeatureControlsSnapshot {
        switch source {
            case let .bundle(name, ext, bundle):
                return try await BundleFeatureControlRepository(
                    bundle: bundle,
                    resourceName: name,
                    resourceExtension: ext
                ).fetchSnapshot()

            case let .inMemory(json):
                return try await InMemoryFeatureControlRepository(json: json).fetchSnapshot()
        }
    }
}
