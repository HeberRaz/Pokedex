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

/// Forwards traces to multiple tracers.
struct CompositeDecisionTracer: DecisionTracing {
    private let tracers: [DecisionTracing]

    init(_ tracers: [DecisionTracing]) {
        self.tracers = tracers
    }

    func record(_ trace: DecisionTrace) {
        tracers.forEach { $0.record(trace) }
    }
}

/// Applies a simple probabilistic sampling before forwarding the trace.
struct SamplingDecisionTracer: DecisionTracing {
    private let base: DecisionTracing
    private let sampleRate: Double // 0.0 ... 1.0

    init(base: DecisionTracing, sampleRate: Double) {
        self.base = base
        self.sampleRate = max(0.0, min(sampleRate, 1.0))
    }

    func record(_ trace: DecisionTrace) {
        guard sampleRate > 0 else { return }
        if sampleRate >= 1.0 {
            base.record(trace)
            return
        }

        // Very lightweight sampler using arc4random_uniform.
        let threshold = UInt32(sampleRate * 10000.0)
        let value = arc4random_uniform(10000)
        if value < threshold {
            base.record(trace)
        }
    }
}

/// Publishes all traces via NotificationCenter so that observers
/// (e.g. analytics or observability layers) can subscribe and forward
/// them without tight coupling to the FTT module.
final class NotificationCenterDecisionTracer: DecisionTracing {

    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    func record(_ trace: DecisionTrace) {
        notificationCenter.post(
            name: .featureControlDecisionTrace,
            object: nil,
            userInfo: ["trace": trace]
        )
    }
}

extension Notification.Name {
    static let featureControlDecisionTrace = Notification.Name("featureControlDecisionTrace")
}
