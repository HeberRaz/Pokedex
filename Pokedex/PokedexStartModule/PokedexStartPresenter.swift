//
//  PokedexStartPresenter.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 15/11/22.
//

import Foundation

final class PokedexStartPresenter {
    var router: PokedexStartRouterProtocol?
}

extension PokedexStartPresenter: PokedexStartPresenterProtocol {
    func willPresentPokemonTable() {
        router?.presentMainModule()
    }
}
