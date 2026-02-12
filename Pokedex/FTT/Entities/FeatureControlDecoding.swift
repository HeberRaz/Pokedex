//
//  FeatureControlDecoding.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

public enum FeatureControlsDecoding {
    public static func decode(from jsonData: Data) throws -> FeatureControlsSnapshot {
        let decoder = JSONDecoder()
        // futuro: decoder.dateDecodingStrategy = ...
        return try decoder.decode(FeatureControlsSnapshot.self, from: jsonData)
    }
}
