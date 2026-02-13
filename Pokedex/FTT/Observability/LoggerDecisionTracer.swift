//
//  LoggerDecisionTracer.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//


import Foundation
import os

final class LoggerDecisionTracer: DecisionTracing {

    private let logger = Logger(subsystem: "com.heber.Pokedex", category: "FTT.Decisions")

    func record(_ trace: DecisionTrace) {
        // Evitamos logs enormes y mantenemos formato estable.
        let meta = trace.metadata
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")

        logger.info("[FTT] id=\(trace.controlId, privacy: .public) type=\(trace.controlType?.rawValue ?? "nil", privacy: .public) kind=\(trace.kind.rawValue, privacy: .public) reason=\(trace.reason.rawValue, privacy: .public) meta=\(meta, privacy: .public)")
    }
}