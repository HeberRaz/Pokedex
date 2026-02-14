//
//  FeatureControlSnapShot.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

public struct FeatureControlsSnapshot: Codable, Sendable {
    public let schemaVersion: Int
    public let controls: [FeatureControlDTO]
}
