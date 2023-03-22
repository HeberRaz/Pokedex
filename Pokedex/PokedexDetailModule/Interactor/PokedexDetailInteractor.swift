//
//  PokedexDetailInteractor.swift
//  Pokedex
//
//  Created by Heber Alvarez on 20/03/23.
//

import Foundation

protocol PokedexDetailInteractorInputProtocol {
    var presenter: PokedexDetailInteractorOutputProtocol? { get set }
    var dataManager: PokedexDetailDataManagerInputProtocol? { get set }

}

protocol PokedexDetailDataManagerOutputProtocol {

}

final class PokedexDetailInteractor {
    weak var presenter: PokedexDetailInteractorOutputProtocol?
    var dataManager: PokedexDetailDataManagerInputProtocol?

}

extension PokedexDetailInteractor: PokedexDetailInteractorInputProtocol {

}

extension PokedexDetailInteractor: PokedexDetailDataManagerOutputProtocol {

}

