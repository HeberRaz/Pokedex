//
//  FeatureControlClientTests.swift
//  PokedexTests
//
//  Created by Heber Alvarez on 13/02/26.
//


import XCTest
@testable import Pokedex

final class FeatureControlClientTests: XCTestCase {

    private final class FakeService: FeatureControlAdvancedService {
        var refreshCalled = false
        var enabled: [String: Bool] = [:]
        var variants: [String: ExperimentVariant] = [:]
        var throttles: [String: ThrottleConfig] = [:]

        func refresh() async throws { refreshCalled = true }
        func isEnabled(_ id: String) -> Bool { enabled[id] ?? false }
        func variant(for experimentId: String) -> ExperimentVariant? { variants[experimentId] }
        func throttleConfig(for throttleId: String) -> ThrottleConfig? { throttles[throttleId] }
    }

    func test_client_delegates_calls_to_service() async throws {
        let service = FakeService()
        service.enabled["flag_a"] = true
        service.variants["exp_a"] = .b
        service.throttles["throttle_a"] = ThrottleConfig(maxPerMinute: 3)

        let client = DefaultFeatureControlClient(service: service)

        try await client.refresh()
        XCTAssertTrue(service.refreshCalled)

        XCTAssertTrue(client.isEnabled("flag_a"))
        XCTAssertEqual(client.variant(for: "exp_a"), .b)
        XCTAssertEqual(client.throttleConfig(for: "throttle_a")?.maxPerMinute, 3)
    }
}
