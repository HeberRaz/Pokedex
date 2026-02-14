//
//  DefaultFeatureControlClient.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//

import Foundation

final class DefaultFeatureControlClient: FeatureControlClient {

    private let service: FeatureControlAdvancedService

    init(service: FeatureControlAdvancedService) {
        self.service = service
    }

    func refresh() async throws {
        try await service.refresh()
    }

    func isEnabled(_ id: String) -> Bool {
        service.isEnabled(id)
    }

    func variant(for experimentId: String) -> ExperimentVariant? {
        service.variant(for: experimentId)
    }

    func throttleConfig(for throttleId: String) -> ThrottleConfig? {
        service.throttleConfig(for: throttleId)
    }

    func controlsCount() -> Int {
        service.controlsCount()
    }
}
