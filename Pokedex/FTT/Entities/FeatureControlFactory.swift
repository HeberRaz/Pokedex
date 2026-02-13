//
//  FeatureControlFactory.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

protocol FeatureControlFactory {
    func makeClient() -> FeatureControlClient
}
