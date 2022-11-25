//
//  PokedexProtocols.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import Foundation
import UIKit

// MARK: - VIPER protocols

// Presenter > Router
protocol PokedexMainRouterProtocol: AnyObject {
    func createPokedexMainModule() -> UIViewController
    func popViewController(from view: PokedexMainViewControllerProtocol)
    func presentPokemonDetail(named pokemonName: String, from view: PokedexMainViewControllerProtocol?)
}

// View > Presenter
protocol PokedexMainViewControllerProtocol: AnyObject {
    var presenter: PokedexMainPresenterProtocol? { get set }
    
    var pokemonList: [PokemonCellModel] { get set }
    
    func reloadInformation()
    func fillPokemonList()
}

// Presenter > View
protocol PokedexMainPresenterProtocol: AnyObject {
    var view: PokedexMainViewControllerProtocol? { get set }
    var router: PokedexMainRouterProtocol? { get set }
    var model: [Pokemon] { get set }
    
    var totalPokemonCount: Int? { get set }
    
    func didSelectRowAt(_ indexPath: IndexPath)
    func shouldPrefetch(at indexPaths: [IndexPath])
    func isLoadingCell(for indexPath: IndexPath) -> Bool
    
    func reloadSections()
    func willPopController(from view: PokedexMainViewControllerProtocol)
    func willFetchPokemons()
}

extension PokedexMainPresenterProtocol {
    func linkDependencies(view: PokedexMainViewControllerProtocol, router: PokedexMainRouterProtocol, interactor: PokedexMainInteractorInputProtocol) {
        self.view = view
        (self as? PokedexMainInteractorOutputProtocol)?.interactor = interactor
        self.router = router
    }
}

// Interactor > Presenter
protocol PokedexMainInteractorInputProtocol: AnyObject {
    var presenter: PokedexMainInteractorOutputProtocol? { get set }
    var remoteData: PokedexMainRemoteDataInputProtocol? { get set }
    
    var nextBlockUrl: String? { get set }
    
    func fetchPokemonBlock(_ urlString: String?)
    func fetchDetailFrom(pokemonName: String)
    
    func linkDependencies(remoteData: PokedexMainRemoteDataInputProtocol, presenter: PokedexMainInteractorOutputProtocol)
}

extension PokedexMainInteractorInputProtocol {
    func fetchPokemonBlock(_ urlString: String? = nil) {
        fetchPokemonBlock(nil)
    }
    
    func linkDependencies(remoteData: PokedexMainRemoteDataInputProtocol, presenter: PokedexMainInteractorOutputProtocol) {
        self.presenter = presenter
        self.remoteData = remoteData
    }
}

// Presenter > Interactor
protocol PokedexMainInteractorOutputProtocol: AnyObject {
    var interactor: PokedexMainInteractorInputProtocol? { get set }
    
    var isFetchInProgress: Bool { get set }
    
    func onReceivedData(with pokemonBlock: PokemonBlock)
    func onReceivedPokemon(_ pokemons: Pokemon)
}

// Interactor > RemoteData
protocol PokedexMainRemoteDataInputProtocol {
    var interactor: PokedexRemoteDataOutputProtocol? { get set }
    
    func requestPokemonBlock(_ urlString: String?)
    func requestPokemon(_ name: String)
}

// RemoteData > Interactor
protocol PokedexRemoteDataOutputProtocol: AnyObject {
    func handlePokemonBlockFetch(_ pokemonBlock: PokemonBlock)
    func handleFetchedPokemon(_ pokemonDetail: PokemonDetail)
    func handleService(error: Error)
}
