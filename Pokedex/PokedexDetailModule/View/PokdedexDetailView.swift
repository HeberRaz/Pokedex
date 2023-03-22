//
//  PokdedexDetailView.swift
//  Pokedex
//
//  Created by Heber Alvarez on 20/03/23.
//

import UIKit
protocol PokedexDetailViewControllerProtocol: AnyObject {
    var presenter: PokedexDetailPresenterProtocol? { get set }
}

final class PokedexDetailViewController: UIViewController {
    var presenter: PokedexDetailPresenterProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension PokedexDetailViewController: PokedexDetailViewControllerProtocol {

}
