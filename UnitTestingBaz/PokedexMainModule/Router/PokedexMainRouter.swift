//
//  TransverseSearcherRouter.swift
//  UnitTestingBaz
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import UIKit

final class PokedexMainRouter {
    // MARK: - Properties
    var view: PokedexMainViewControllerProtocol?
    var interactor: (PokedexMainInteractorInputProtocol & PokedexRemoteDataOutputProtocol)?
    var presenter: (PokedexMainPresenterProtocol & PokedexMainInteractorOutputProtocol)?
    var router: PokedexMainRouterProtocol?
    var remoteData: PokedexMainRemoteDataInputProtocol?
}

extension PokedexMainRouter: PokedexMainRouterProtocol {
    
    func createPokedexMainModule() -> UINavigationController {
        buildModuleComponents()
        linkDependencies()
        guard let viewController: UIViewController = view as? UIViewController else {
            return UINavigationController()
        }
        let navigationController: UINavigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }
    
    func popViewController(from view: PokedexMainViewControllerProtocol) {
        guard let viewController: UIViewController = view as? UIViewController else { return }
        viewController.navigationController?.popViewController(animated: true)
    }
    
    func presentPokemonDetail(named pokemonNake: String) {
        guard let viewController: UIViewController = self.view as? UIViewController else { return }
        //let detailRouter = PokedexDetailRouter()
        let vc = ViewController()
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Private methods
    
    private func buildModuleComponents() {
        view = PokedexMainViewController()
        interactor = PokedexMainInteractor()
        presenter = PokedexMainPresenter()
        remoteData = PokedexMainRemoteDataManager()
        router = self
    }
    
    private func linkDependencies() {
        view?.presenter = self.presenter
        presenter?.view = self.view
        presenter?.interactor = self.interactor
        presenter?.router = self
        interactor?.remoteData = self.remoteData
        interactor?.presenter = self.presenter
        remoteData?.interactor = self.interactor
    }
}
