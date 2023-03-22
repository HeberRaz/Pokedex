//
//  PokedexDetailRouter.swift
//  Pokedex
//
//  Created by Heber Alvarez on 20/03/23.
//

import UIKit

protocol PokedexDetailRouterProtocol {
    static func createPokedexDetailModule() -> UIViewController
}

final class PokedexDetailRouter {
    
}

extension PokedexDetailRouter: PokedexDetailRouterProtocol {
    static func createPokedexDetailModule() -> UIViewController {
        let view = PokedexDetailViewController()
        let presenter = PokedexDetailPresenter()
        let interactor = PokedexDetailInteractor()
        let dataManager = PokedexDetailDataManager()
        return view
    }
}
