//
//  TransverseSearcherRouter.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import UIKit

final class PokedexMainRouter {
}

extension PokedexMainRouter: PokedexMainRouterProtocol {
    
    func createPokedexMainModule() -> UIViewController {
        let view = PokedexMainViewController()
        let interactor = PokedexMainInteractor()
        let presenter = PokedexMainPresenter()
        let remoteData = PokedexMainRemoteDataManager(service: ServiceAPI(session: URLSession.shared))

        view.presenter = presenter
        presenter.linkDependencies(view: view, router: self, interactor: interactor)
        interactor.linkDependencies(remoteData: remoteData, presenter: presenter)
        remoteData.interactor = interactor

        return (view as UIViewController)
    }
    
    func popViewController(from view: PokedexMainViewControllerProtocol) {
        guard let viewController: UIViewController = view as? UIViewController else { return }
        viewController.navigationController?.popViewController(animated: true)
    }
    
    func presentPokemonDetail(named pokemonNake: String, from view: PokedexMainViewControllerProtocol?) {
        guard let viewController: UIViewController = view as? UIViewController else { return }
        //let detailRouter = PokedexDetailRouter()
        let vc = ViewController()
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Private methods
    
    private func buildModuleComponents() {
       
    }
    
    private func linkDependencies() {
        
    }
}
