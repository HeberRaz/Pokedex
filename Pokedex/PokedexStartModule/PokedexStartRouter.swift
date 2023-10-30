//
//  PokedexStartRouter.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 14/11/22.
//

import Foundation
import UIKit

final class PokedexStartRouter {
    // MARK: Protocol properties
    var view: PokedexStartViewControllerProtocol?
    var presenter: PokedexStartPresenterProtocol?
    var router: PokedexStartRouterProtocol?
    
}

extension PokedexStartRouter: PokedexStartRouterProtocol {
    
    func createStartModule() -> UINavigationController {
        buildModuleComponents()
        linkDependencies()
        guard let viewController: UIViewController = view as? UIViewController else {
            return UINavigationController()
        }
        let navigationController: UINavigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }
    
    func presentMainModule() {
        guard let viewController: UIViewController = (self.view as? UIViewController) else { return }
        let mainRouter: PokedexMainRouterProtocol = PokedexMainRouter()
        let mainViewController = mainRouter.createPokedexMainModule()
        mainViewController.modalPresentationStyle = .overFullScreen
        mainViewController.modalTransitionStyle = .coverVertical
        viewController.navigationController?.present(mainViewController, animated: true)
    }
    
    // MARK: Private methods
    
    private func buildModuleComponents() {
        view = PokedexStartViewController()
        presenter = PokedexStartPresenter()
        router = self
        
    }
    
    private func linkDependencies() {
        view?.presenter = self.presenter
        presenter?.router = self
    }
}
