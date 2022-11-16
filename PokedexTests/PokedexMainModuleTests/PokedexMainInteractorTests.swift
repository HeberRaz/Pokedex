//
//  PokedexMainInteractorTests.swift
//  PokedexTests
//
//  Created by Ivan Tecpanecatl Martinez on 16/11/22.
//

import XCTest
@testable import Pokedex

class PokedexMainInteractorTests: XCTestCase {
    
    var sut: PokedexMainInteractorInputProtocol!
    var remoteDataManager: PokedexMainRemoteDataManagerMock!

    override func setUp() {
        super.setUp()
        sut = PokedexMainInteractor()
        remoteDataManager = PokedexMainRemoteDataManagerMock()
        sut.remoteData = remoteDataManager
    }

    override func tearDown()  {
        sut = nil
        remoteDataManager = nil
        super.tearDown()
    }
    
    func testfetchPokemonBlock(){
        let urlString = ""
        sut.fetchPokemonBlock(urlString)
        XCTAssert(remoteDataManager.calls.contains(.requestPokemonBlock))
    }

}
