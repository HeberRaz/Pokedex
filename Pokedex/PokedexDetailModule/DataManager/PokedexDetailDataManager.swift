//
//  PokedexDetailDataManager.swift
//  Pokedex
//
//  Created by Heber Alvarez on 20/03/23.
//

import Foundation

protocol PokedexDetailDataManagerInputProtocol {
    var interactor: PokedexDetailDataManagerOutputProtocol? { get set }
}

final class PokedexDetailDataManager {
    var interactor: PokedexDetailDataManagerOutputProtocol?
}
