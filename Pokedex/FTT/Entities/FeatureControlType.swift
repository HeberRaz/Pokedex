//
//  FeatureControlType.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

public enum FeatureControlType: String, Codable, Sendable {
    case flag
    case rollout
    case experiment
    case throttle
}
