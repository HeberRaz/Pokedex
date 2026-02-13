//
//  FallbackFeatureControlRepositoryTests.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//

import XCTest
@testable import Pokedex

final class FallbackFeatureControlRepositoryTests: XCTestCase {

    // MARK: - Test Doubles

    private struct TestError: Error, Equatable {}

    private final class RepositoryStub: FeatureControlRepository {
        enum Mode {
            case success(FeatureControlsSnapshot)
            case failure(Error)
        }

        var mode: Mode
        private(set) var fetchCalls: Int = 0

        init(mode: Mode) {
            self.mode = mode
        }

        func fetchSnapshot() async throws -> FeatureControlsSnapshot {
            fetchCalls += 1
            switch mode {
                case .success(let snapshot): return snapshot
                case .failure(let error): throw error
            }
        }
    }

    // MARK: - Helpers

    private func makeSnapshot(_ controls: [FeatureControlDTO] = []) -> FeatureControlsSnapshot {
        FeatureControlsSnapshot(schemaVersion: 1, controls: controls)
    }

    // MARK: - Tests

    func test_fetchSnapshot_primarySuccess_returnsPrimarySnapshot_doesNotCallFallback() async throws {
        let primarySnapshot = makeSnapshot([.init(id: "flag_a", type: .flag, enabled: true)])
        let primary = RepositoryStub(mode: .success(primarySnapshot))
        let fallback = RepositoryStub(mode: .success(makeSnapshot()))

        let sut = FallbackFeatureControlRepository(primary: primary, fallback: fallback)

        let result = try await sut.fetchSnapshot()

        XCTAssertEqual(result.schemaVersion, 1)
        XCTAssertEqual(result.controls.count, 1)
        XCTAssertEqual(result.controls.first?.id, "flag_a")

        XCTAssertEqual(primary.fetchCalls, 1)
        XCTAssertEqual(fallback.fetchCalls, 0)
    }

    func test_fetchSnapshot_primaryFailure_fallsBack_returnsFallbackSnapshot_andCallsOnPrimaryError() async throws {
        let error = TestError()

        let primary = RepositoryStub(mode: .failure(error))
        let fallbackSnapshot = makeSnapshot([.init(id: "flag_b", type: .flag, enabled: false)])
        let fallback = RepositoryStub(mode: .success(fallbackSnapshot))

        var capturedError: Error?
        let sut = FallbackFeatureControlRepository(
            primary: primary,
            fallback: fallback,
            onPrimaryError: { capturedError = $0 }
        )

        let result = try await sut.fetchSnapshot()

        XCTAssertEqual(result.controls.count, 1)
        XCTAssertEqual(result.controls.first?.id, "flag_b")

        XCTAssertEqual(primary.fetchCalls, 1)
        XCTAssertEqual(fallback.fetchCalls, 1)

        XCTAssertNotNil(capturedError)
        XCTAssertTrue(capturedError is TestError)
    }

    func test_fetchSnapshot_primaryFailure_andFallbackFailure_throwsFallbackError() async {
        let primaryError = TestError()
        let fallbackError = NSError(domain: "fallback", code: -123)

        let primary = RepositoryStub(mode: .failure(primaryError))
        let fallback = RepositoryStub(mode: .failure(fallbackError))

        let sut = FallbackFeatureControlRepository(primary: primary, fallback: fallback)

        do {
            _ = try await sut.fetchSnapshot()
            XCTFail("Expected fetchSnapshot to throw")
        } catch {
            // Should throw the fallback error (the second failure)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "fallback")
            XCTAssertEqual(nsError.code, -123)
        }

        XCTAssertEqual(primary.fetchCalls, 1)
        XCTAssertEqual(fallback.fetchCalls, 1)
    }

    func test_fetchSnapshot_primaryFailure_doesNotRequireOnPrimaryErrorClosure() async throws {
        let primary = RepositoryStub(mode: .failure(TestError()))
        let fallbackSnapshot = makeSnapshot()
        let fallback = RepositoryStub(mode: .success(fallbackSnapshot))

        let sut = FallbackFeatureControlRepository(primary: primary, fallback: fallback, onPrimaryError: nil)

        let result = try await sut.fetchSnapshot()

        XCTAssertEqual(result.controls.count, 0)
        XCTAssertEqual(primary.fetchCalls, 1)
        XCTAssertEqual(fallback.fetchCalls, 1)
    }
}
