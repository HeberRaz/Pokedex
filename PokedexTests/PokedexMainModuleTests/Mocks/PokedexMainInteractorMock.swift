//
//  PokedexMainInteractorMock.swift
//  PokedexTests
//
//  Created by Heber Raziel Alvarez Ruedas on 15/11/22.
//

import Foundation
@testable import Pokedex

enum PokedexMainInteractorMockCalls {
    case fetchDetailFromPokemonName
    case handlePokemonBlockFetch
    case handleFetchedPokemonDetail
    case handleServiceError
}

final class PokedexMainInteractorMock: PokedexMainInteractorInputProtocol, PokedexRemoteDataOutputProtocol {
    // MARK: Protocol properties
    var presenter: PokedexMainInteractorOutputProtocol?
    var remoteData: PokedexMainRemoteDataInputProtocol?
    var nextBlockUrl: String?
    
    var calls: [PokedexMainInteractorMockCalls] = []
    var catchedError: ServiceError?
    
    func fetchDetailFrom(pokemonName: String) {
        calls.append(.fetchDetailFromPokemonName)
    }
    
    func handlePokemonBlockFetch(_ pokemonBlock: PokemonBlock) {
        calls.append(.handlePokemonBlockFetch)
    }
    
    func handleFetchedPokemon(_ pokemonDetail: PokemonDetail) {
        calls.append(.handleFetchedPokemonDetail)
    }
    
    func handleService(error: Error) {
        self.catchedError = (error as? ServiceError)
        calls.append(.handleServiceError)
    }
}
