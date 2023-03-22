//
//  PokedexDetailPresenter.swift
//  Pokedex
//
//  Created by Heber Alvarez on 20/03/23.
//

import Foundation

protocol PokedexDetailPresenterProtocol {
    var view: PokedexDetailViewControllerProtocol? { get set }
    var interactor: PokedexDetailInteractorInputProtocol? { get set }
    var router: PokedexDetailRouterProtocol? { get set }
}

protocol PokedexDetailInteractorOutputProtocol: AnyObject {
    
}

final class PokedexDetailPresenter {
    weak var view: PokedexDetailViewControllerProtocol?
    var interactor: PokedexDetailInteractorInputProtocol?
    var router: PokedexDetailRouterProtocol?
}

extension PokedexDetailPresenter: PokedexDetailPresenterProtocol {

}
