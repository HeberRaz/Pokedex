//
//  FeatureControlRepository.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

public protocol FeatureControlRepository {
    func fetchSnapshot() async throws -> FeatureControlsSnapshot
}
