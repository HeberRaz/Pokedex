//
//  DecisionTracing.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//


import Foundation

protocol DecisionTracing {
    func record(_ trace: DecisionTrace)
}

struct NoopDecisionTracer: DecisionTracing {
    func record(_ trace: DecisionTrace) {}
}