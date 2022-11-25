//
//  PokedexMainPresenter.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import Foundation

final class PokedexMainPresenter {
    
    // MARK: - Protocol properties
    
    weak var view: PokedexMainViewControllerProtocol?
    var interactor: PokedexMainInteractorInputProtocol?
    var router: PokedexMainRouterProtocol?
    
    var model: [Pokemon] = []
    var isFetchInProgress: Bool = false
    var totalPokemonCount: Int?
    
    // MARK: - Private properties
    
    private typealias Constants = PokedexMainConstants
    private var nextBlockUrl: String?
}

extension PokedexMainPresenter: PokedexMainPresenterProtocol {
    
    func didSelectRowAt(_ indexPath: IndexPath) {
        let pokemonName: String = view?.pokemonList[indexPath.row].name ?? ""
        router?.presentPokemonDetail(named: pokemonName, from: view)
    }
    
    func willPopController(from view: PokedexMainViewControllerProtocol) {
        router?.popViewController(from: view)
    }
    
    func reloadSections() {
        view?.reloadInformation()
    }
    
    func willFetchPokemons() {
        interactor?.fetchPokemonBlock()
    }
    
    func shouldPrefetch(at indexPaths: [IndexPath]) {
        if indexPaths.contains(where: isLoadingCell) {
            guard !isFetchInProgress else { return }
            isFetchInProgress = true
            interactor?.fetchPokemonBlock(nextBlockUrl ?? "")
        }
    }
    
    func isLoadingCell(for indexPath: IndexPath) -> Bool {
        let currentCount: Int = model.count
        let shouldFetchNextPokemonBlock: Bool = indexPath.row >= currentCount - 1
        return shouldFetchNextPokemonBlock
    }
}

extension PokedexMainPresenter: PokedexMainInteractorOutputProtocol {
    
    func onReceivedData(with pokemonBlock: PokemonBlock) {
        guard let pokemonResults: [PokemonBlockResult] = pokemonBlock.results else { return }
        self.nextBlockUrl = pokemonBlock.next
        self.totalPokemonCount = pokemonBlock.count
        for pokemon in pokemonResults {
            guard let pokemonName: String = pokemon.name else { return }
            interactor?.fetchDetailFrom(pokemonName: pokemonName)
        }
    }
    
    func onReceivedPokemon(_ pokemon: Pokemon) {
        self.model.append(pokemon)
        view?.fillPokemonList()
    }
}
