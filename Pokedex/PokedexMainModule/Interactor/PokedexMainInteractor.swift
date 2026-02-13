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
    private let featureRepository: FeatureControlRepository
    private let identityProvider: UserIdentityProvider

    init(
        presenter: PokedexMainInteractorOutputProtocol? = nil,
        remoteData: PokedexMainRemoteDataInputProtocol? = nil,
        nextBlockUrl: String? = nil,
        pokemonList: [Pokemon] = [],
        featureRepository: FeatureControlRepository,
        identityProvider: UserIdentityProvider
    ) {
        self.presenter = presenter
        self.remoteData = remoteData
        self.nextBlockUrl = nextBlockUrl
        self.pokemonList = pokemonList
        self.featureRepository = featureRepository
        self.identityProvider = identityProvider
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
                let snapshot = try await featureRepository.fetchSnapshot()
                await MainActor.run {
                    presenter?.onLoadedFeatureControls(count: snapshot.controls.count)
                }
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
