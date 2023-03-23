//
//  PokedexMainRemoteDataTests.swift
//  PokedexTests
//
//  Created by Heber Raziel Alvarez Ruedas on 15/11/22.
//

import XCTest
@testable import Pokedex

class PokedexMainRemoteDataTests: XCTestCase {
    // System Under Test
    private var sut: PokedexMainRemoteDataInputProtocol!
    private var interactorMock: PokedexMainInteractorMock!
    private var serviceMock: ServiceMock!
    private var sessionMock: URLSessionMock!
    

    override func setUp() {
        super.setUp()
        sessionMock = URLSessionMock()
        serviceMock = ServiceMock(sessionMock: sessionMock)
        sut = PokedexMainRemoteDataManager(service: serviceMock)
        interactorMock = PokedexMainInteractorMock()
        sut.interactor = interactorMock
    }

    override func tearDown() {
        sut = nil
        interactorMock = nil
        sessionMock = nil
        serviceMock = nil
        super.tearDown()
    }

    func testRequestPokemonBlock_whenResponseError_callsHandleServiceError() {
        // Given
        let expectation = XCTestExpectation(description: "Wait for requestPokemonBlock completion")
        sessionMock.data = Data()
        let urlString = "https://fakeurl.com"
        // When
        sut.requestPokemonBlock(urlString)
        expectation.fulfill()
        // Then
        wait(for: [expectation], timeout: 0.1)
        XCTAssert(interactorMock.calls.contains(.handleServiceError))
        XCTAssertEqual(interactorMock.catchedError, .response, "Se espera que el código regrese del tipo ServiceError.response")
    }
    
    func testRequestPokemonBlock_whenNoDataError_callsInteractorHandler() {
        // Given
        let expectation = XCTestExpectation(description: "Wait for requestPokemonBlock completion")
        let urlString = "https://fakeurl.com"
        // When
        sut.requestPokemonBlock(urlString)
        expectation.fulfill()
        // Then
        wait(for: [expectation], timeout: 0.1)
        XCTAssert(interactorMock.calls.contains(.handleServiceError))
        XCTAssertEqual(interactorMock.catchedError, .noData, "Se espera que el código regrese del tipo ServiceError.noData")
    }
    
    func testRequestPokemonBlock_whenStatusCode200_callsHandlePokemonBlockFetch() {
        // Given
        for statusCode in 200...299 {
            let expectation = XCTestExpectation(description: "Wait for completion of \(statusCode)")
            let url: URL = URL(fileURLWithPath: "")
            let urlString = "https://fakeurl.com"
            sessionMock.urlResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
            sessionMock.data = PokedexMainFakes().pokemonBlock
            sessionMock.expectation = expectation
            // When
            sut.requestPokemonBlock(urlString)

            // Then
            wait(for: [expectation], timeout: 0.1)
            XCTAssert(interactorMock.calls.contains(.handlePokemonBlockFetch))
            XCTAssertFalse(interactorMock.calls.contains(.handleServiceError))
        }
    }
    
    func testRequestPokemonBlock_whenStatusCode300To500_callsHandlePokemonBlockFetch() {
        // Given
        for statusCode in 300...500 {
            let url: URL = URL(fileURLWithPath: "")
            let urlString = "https://fakeurl.com"
            sessionMock.urlResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
            sessionMock.data = PokedexMainFakes().pokemonBlock
            // When
            sut.requestPokemonBlock(urlString)
            // Then
            XCTAssert(interactorMock.calls.contains(.handleServiceError))
            XCTAssertFalse(interactorMock.calls.contains(.handlePokemonBlockFetch))
        }
    }
}
