//
//  DecisionReason.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//


import Foundation

enum DecisionReason: String, Sendable {
    case override
    case snapshotEvaluator
    case missingSnapshot
    case missingControl
    case invalidConfig
    case `default`
}

enum DecisionKind: String, Sendable {
    case bool
    case variant
    case throttle
}

enum DecisionOutcome: Sendable, Equatable {
    case bool(Bool)
    case variant(ExperimentVariant?)
    case throttle(ThrottleConfig?)
}

struct DecisionTrace: Sendable, Equatable {
    let controlId: String
    let controlType: FeatureControlType?
    let kind: DecisionKind
    let outcome: DecisionOutcome
    let reason: DecisionReason
    let metadata: [String: String]
    let timestamp: Date

    init(
        controlId: String,
        controlType: FeatureControlType?,
        kind: DecisionKind,
        outcome: DecisionOutcome,
        reason: DecisionReason,
        metadata: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.controlId = controlId
        self.controlType = controlType
        self.kind = kind
        self.outcome = outcome
        self.reason = reason
        self.metadata = metadata
        self.timestamp = timestamp
    }
}