//
//  FeatureControlRepositoryError.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

public enum FeatureControlRepositoryError: Error, LocalizedError {
    case resourceNotFound(name: String, ext: String)
    case invalidUTF8
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
            case let .resourceNotFound(name, ext):
                return "Feature controls file not found: \(name).\(ext)"
            case .invalidUTF8:
                return "Feature controls file could not be read as UTF-8."
            case let .decodingFailed(error):
                return "Failed to decode FeatureControlsSnapshot: \(error)"
        }
    }
}
