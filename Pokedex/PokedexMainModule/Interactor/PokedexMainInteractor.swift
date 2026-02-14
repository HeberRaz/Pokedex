//
//  PokedexMainInteractor.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import Foundation

class PokedexMainInteractor {
    
    // MARK: - Protocol properties
    
    weak var presenter: PokedexMainInteractorOutputProtocol?
    var remoteData: PokedexMainRemoteDataInputProtocol?
    
    var nextBlockUrl: String?
    
    // MARK: - Private properties
    private var pokemonList: [Pokemon]
    private let featureControl: FeatureControlClient

    init(
        presenter: PokedexMainInteractorOutputProtocol? = nil,
        remoteData: PokedexMainRemoteDataInputProtocol? = nil,
        nextBlockUrl: String? = nil,
        pokemonList: [Pokemon] = [],
        featureControl: FeatureControlClient
    ) {
        self.presenter = presenter
        self.remoteData = remoteData
        self.nextBlockUrl = nextBlockUrl
        self.pokemonList = pokemonList
        self.featureControl = featureControl
    }
}

extension PokedexMainInteractor: PokedexMainInteractorInputProtocol {
    func fetchPokemonBlock(_ urlString: String?) {
        remoteData?.requestPokemonBlock(urlString)
    }
    
    func fetchDetailFrom(pokemonName: String) {
        remoteData?.requestPokemon(pokemonName)
    }

    func loadFeatureControls() {
        Task {
            do {
                try await featureControl.refresh()

                let flag    = featureControl.isEnabled("checkout_new_flow")
                let rollout = featureControl.isEnabled("checkout_new_flow_rollout")
                let variant = featureControl.variant(for: "home_header_experiment")
                let throttle = featureControl.throttleConfig(for: "login_attempts")?.maxPerMinute ?? 0

                await MainActor.run { [weak presenter] in
                    presenter?.onLoadedFeatureControls(count: featureControl.controlsCount())
                }

                #if DEBUG
                let variantDescription: String
                if let variant {
                    variantDescription = "\(variant)"
                } else {
                    variantDescription = "nil (missing or misconfigured)"
                }

                print("""
                FLAG checkout_new_flow = \(flag)
                ROLLOUT checkout_new_flow_rollout = \(rollout)
                EXP home_header_experiment = \(variantDescription)
                THROTTLE login_attempts = \(throttle)
                """)
                #endif
            } catch {
                await MainActor.run {
                    presenter?.onFailedLoadingFeatureControls(error)
                }
            }
        }
    }
}

extension PokedexMainInteractor: PokedexRemoteDataOutputProtocol {
    func handlePokemonBlockFetch(_ pokemonBlock: PokemonBlock) {
        self.nextBlockUrl = pokemonBlock.next
        self.presenter?.isFetchInProgress = false
        self.presenter?.onReceivedData(with: pokemonBlock)
    }
    
    func handleFetchedPokemon(_ pokemonDetail: PokemonDetail) {
        remoteData?.requestImageData(urlString: pokemonDetail.sprites.frontDefault, completion: { data in
            guard let imageData = data else { return }
            self.presenter?.onReceivedPokemon(Pokemon(from: pokemonDetail, imageData: imageData))
        })
    }
    
    
    func handleService(error: Error) {
        // TODO: Return data to presenter
        debugPrint("Returns data to presenter", error)
    }
}
