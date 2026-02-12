//
//  FeatureControlDTO.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

public struct FeatureControlDTO: Decodable, Sendable, Identifiable {
    public let id: String
    public let type: FeatureControlType
    public let enabled: Bool

    // Rollout
    public let percentage: Int?

    // Experiment
    public let variants: [String: Int]?

    // Throttle
    public let maxPerMinute: Int?

    public init(
        id: String,
        type: FeatureControlType,
        enabled: Bool,
        percentage: Int? = nil,
        variants: [String: Int]? = nil,
        maxPerMinute: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.enabled = enabled
        self.percentage = percentage
        self.variants = variants
        self.maxPerMinute = maxPerMinute
    }
}
