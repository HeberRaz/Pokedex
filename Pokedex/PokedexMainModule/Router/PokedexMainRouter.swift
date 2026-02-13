//
//  TransverseSearcherRouter.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import UIKit

final class PokedexMainRouter: PokedexMainRouterProtocol {
    func createPokedexMainModule() -> UIViewController {
        let view = PokedexMainViewController()
        let interactor = PokedexMainInteractor(
            featureRepository: createFeatureControlRepository(),
            identityProvider: createUserIdentityProvider()
        )
        let presenter = PokedexMainPresenter()
        let service = MainQueueDispatchDecorator(decoratee: ServiceAPI(session: URLSession.shared))
        let remoteData = PokedexMainRemoteDataManager(service: service)

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

    func presentPokemonDetail(named pokemonName: String, from view: PokedexMainViewControllerProtocol?) {
        guard let viewController: UIViewController = view as? UIViewController else { return }
        let emptyViewController = ViewController()
        viewController.navigationController?.pushViewController(emptyViewController, animated: true)
    }

    private func createFeatureControlRepository() -> FeatureControlRepository {
        LocalFeatureControlRepository(
            source: .bundle(name: "feature_controls", ext: "json", bundle: .main)
        )
    }

    private func createUserIdentityProvider() -> UserIdentityProvider {
        DefaultUserIdentityProvider(userDefaults: .standard)
    }
}
