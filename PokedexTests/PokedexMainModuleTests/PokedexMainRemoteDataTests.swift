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

    func testRequestPokemonBlock_whenResponseError_callsInteractorHandler() {
        // Given
        let urlString = "https://fakeurl.com"
        // When
        sut.requestPokemonBlock(urlString)
        // Then
        XCTAssert(interactorMock.calls.contains(.handleServiceError))
        XCTAssertEqual(interactorMock.catchedError, .response, "Se espera que el código regrese del tipo ServiceError.response")
    }
    
    func testRequestPokemonBlock_whenNoDataError_callsInteractorHandler() {
        // Given
        let urlString = "https://fakeurl.com"
        // When
        sut.requestPokemonBlock(urlString)
        // Then
        XCTAssert(interactorMock.calls.contains(.handleServiceError))
        XCTAssertEqual(interactorMock.catchedError, .noData, "Se espera que el código regrese del tipo ServiceError.noData")
    }
    
    func testExample2() {

    }
    
    func testExample3() {

    }
}
