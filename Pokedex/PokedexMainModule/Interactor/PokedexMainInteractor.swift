//
//  PokedexMainInteractor.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import Foundation

class PokedexMainInteractor {
    
    // MARK: - Protocol properties
    
    weak var presenter: PokedexMainInteractorOutputProtocol?
    var remoteData: PokedexMainRemoteDataInputProtocol?
    
    var nextBlockUrl: String?
    
    // MARK: - Private properties
    private var pokemonList: [Pokemon] = []
}

extension PokedexMainInteractor: PokedexMainInteractorInputProtocol {
    func fetchPokemonBlock(_ urlString: String?) {
        remoteData?.requestPokemonBlock(urlString)
    }
    
    func fetchDetailFrom(pokemonName: String) {
        remoteData?.requestPokemon(pokemonName)
    }
}

extension PokedexMainInteractor: PokedexRemoteDataOutputProtocol {
    func handlePokemonBlockFetch(_ pokemonBlock: PokemonBlock) {
        self.nextBlockUrl = pokemonBlock.next
        self.presenter?.isFetchInProgress = false
        self.presenter?.onReceivedData(with: pokemonBlock)
    }
    
    func handleFetchedPokemon(_ pokemonDetail: PokemonDetail) {
        remoteData?.requestImageData(urlString: pokemonDetail.sprites.frontDefault, completion: { data in
            guard let imageData = data else { return }
            self.presenter?.onReceivedPokemon(Pokemon(from: pokemonDetail, imageData: imageData))
        })
    }
    
    
    func handleService(error: Error) {
        // TODO: Return data to presenter
        debugPrint("Returns data to presenter", error)
    }
}
