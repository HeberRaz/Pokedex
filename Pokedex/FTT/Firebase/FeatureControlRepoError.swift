//
//  FeatureControlRepoError.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//


enum FeatureControlRepoError: Error, Sendable, Equatable {
    case missingKey(key: String)
    case emptyJSON(key: String)
    case invalidUTF8(key: String)
    case decodingFailed(key: String, underlyingDescription: String)

    var key: String {
        switch self {
            case .missingKey(let key),
                    .emptyJSON(let key),
                    .invalidUTF8(let key),
                    .decodingFailed(let key, _):
                return key
        }
    }
}
