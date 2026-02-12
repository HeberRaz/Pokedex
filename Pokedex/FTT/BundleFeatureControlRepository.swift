//
//  BundleFeatureControlRepository.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

public final class BundleFeatureControlRepository: FeatureControlRepository {
    private let bundle: Bundle
    private let resourceName: String
    private let resourceExtension: String

    public init(
        bundle: Bundle = .main,
        resourceName: String,
        resourceExtension: String = "json"
    ) {
        self.bundle = bundle
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
    }

    public func fetchSnapshot() async throws -> FeatureControlsSnapshot {
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            throw FeatureControlRepositoryError.resourceNotFound(
                name: resourceName,
                ext: resourceExtension
            )
        }

        do {
            let data = try Data(contentsOf: url)
            do {
                return try FeatureControlsDecoding.decode(from: data)
            } catch {
                throw FeatureControlRepositoryError.decodingFailed(error)
            }
        } catch {
            // si quisieras separar IO vs decode, aquí ya lo tienes
            throw error
        }
    }
}
