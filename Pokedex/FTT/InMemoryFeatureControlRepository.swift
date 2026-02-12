//
//  InMemoryFeatureControlRepository.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

public final class InMemoryFeatureControlRepository: FeatureControlRepository {
    private let json: String

    public init(json: String) {
        self.json = json
    }

    public func fetchSnapshot() async throws -> FeatureControlsSnapshot {
        let data = Data(json.utf8)
        return try FeatureControlsDecoding.decode(from: data)
    }
}
