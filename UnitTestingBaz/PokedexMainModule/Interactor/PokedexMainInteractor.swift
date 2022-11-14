//
//  PokedexMainInteractor.swift
//  UnitTestingBaz
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import Foundation

final class PokedexMainInteractor {
    
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
    
    private func getImageDataFrom(urlString: String) -> Data? {
        guard let imageUrl: URL = URL(string: urlString) else {
            return nil
        }
        do {
            let imageData: Data = try Data(contentsOf: imageUrl)
            return imageData
        } catch {
            return nil
        }
    }
    
    private func handleSuccessfulDetailRequest(with pokemon: PokemonDetail) {
        guard let imageData: Data = self.getImageDataFrom(urlString: pokemon.sprites.frontDefault)
        else { return }
        self.pokemonList.append(Pokemon(from: pokemon, imageData: imageData))
        self.presenter?.onReceivedPokemon(Pokemon(from: pokemon, imageData: imageData))
    }
}

extension PokedexMainInteractor: PokedexRemoteDataOutputProtocol {
    func handlePokemonBlockFetch(_ pokemonBlock: PokemonBlock) {
        self.nextBlockUrl = pokemonBlock.next
        self.presenter?.isFetchInProgress = false
        self.presenter?.onReceivedData(with: pokemonBlock)
    }
    
    func handleFetchedPokemon(_ pokemonDetail: PokemonDetail) {
        guard let imageData: Data = self.getImageDataFrom(urlString: pokemonDetail.sprites.frontDefault)
        else { return }
        self.presenter?.onReceivedPokemon(Pokemon(from: pokemonDetail, imageData: imageData))
    }
    
    
    func handleService(error: Error) {
        // TODO: Return data to presenter
        debugPrint("Returns data to presenter", error)
    }
}
