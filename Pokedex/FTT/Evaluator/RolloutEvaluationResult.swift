//
//  RolloutEvaluationResult.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//


import Foundation

struct RolloutEvaluationResult: Sendable, Equatable {
    let included: Bool
    let bucket: Int
    let percentage: Int
}

struct ExperimentEvaluationResult: Sendable, Equatable {
    let variant: ExperimentVariant
    let bucket: Int
    let weights: [String: Int]
    let thresholdA: Int
    let totalWeight: Int
}
