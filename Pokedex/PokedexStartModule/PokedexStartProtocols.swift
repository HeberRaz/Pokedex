//
//  PokedexStartProtocols.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 15/11/22.
//

import UIKit

protocol PokedexStartRouterProtocol {
    var view: PokedexStartViewControllerProtocol? { get set }
    var presenter: (PokedexStartPresenterProtocol)? { get set }
    var router: PokedexStartRouterProtocol? { get set }
    
    func createStartModule() -> UINavigationController
    func presentMainModule()
}

protocol PokedexStartViewControllerProtocol {
    var presenter: PokedexStartPresenterProtocol? { get set }
}

protocol PokedexStartPresenterProtocol {
    var router: PokedexStartRouterProtocol? { get set }
    
    func willPresentPokemonTable()
}

