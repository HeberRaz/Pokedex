//
//  PokedexDetailRouterTests.swift
//  PokedexTests
//
//  Created by Heber Alvarez on 20/03/23.
//

import XCTest
@testable import Pokedex

final class PokedexDetailRouterTests: XCTestCase {

    var sut: PokedexDetailRouter!

    override func setUp() {
        super.setUp()
        sut = PokedexDetailRouter()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}
