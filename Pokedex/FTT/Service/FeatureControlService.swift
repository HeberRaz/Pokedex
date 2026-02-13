//
//  FeatureControlService.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

protocol FeatureControlService {
    func refresh() async throws
    func isEnabled(_ id: String) -> Bool
}
