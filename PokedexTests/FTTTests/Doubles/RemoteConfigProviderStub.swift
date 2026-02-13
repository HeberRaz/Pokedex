//
//  RemoteConfigProviderStub.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//

@testable import Pokedex
import Foundation

final class RemoteConfigProviderStub: RemoteConfigProviding {

    // MARK: - Configurable state

    var json: String? = nil
    var shouldThrow = false
    var valueSource: RemoteConfigValueSource = .remote

    // MARK: - Call tracking

    private(set) var fetchCalls = 0
    private(set) var stringCalls: [String] = []
    private(set) var sourceCalls: [String] = []

    // MARK: - RemoteConfigProviding

    func fetchAndActivate() async throws {
        fetchCalls += 1
        if shouldThrow {
            throw NSError(domain: "test", code: -1)
        }
    }

    func string(forKey key: String) -> String? {
        stringCalls.append(key)
        return json
    }

    func source(forKey key: String) -> RemoteConfigValueSource {
        sourceCalls.append(key)
        return valueSource
    }
}
