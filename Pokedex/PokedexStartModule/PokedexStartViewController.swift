//
//  PokedexStartViewController.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 14/11/22.
//

import Foundation
import UIKit

final class PokedexStartViewController: UIViewController {
    // MARK: - Protocol properties
    var presenter: PokedexStartPresenterProtocol?
    
    private let start: UIButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        displayButton()
    }
    
    // MARK: - Private functions
    private func displayButton() {
        view.addSubview(start)
        start.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            start.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            start.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            start.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            start.heightAnchor.constraint(equalTo: start.widthAnchor, multiplier: 0.4)
        ])
        start.backgroundColor = .yellow
        start.setTitleColor(.darkGray, for: .normal)
        setupButton()
    }
    
    private func setupButton() {
        start.addTarget(self, action: #selector(launchPokemonTable), for: .touchUpInside)
        start.setTitle("Show Pokemon!", for: .normal)
    }
    
    @objc private func launchPokemonTable() {
        presenter?.willPresentPokemonTable()
    }
    
}

extension PokedexStartViewController: PokedexStartViewControllerProtocol {
    
}
