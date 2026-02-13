//
//  DeterministicBucketer.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation

protocol DeterministicBucketer {
    /// Returns a stable bucket between 0 and 99 for a given (controlId, userId) pair.
    func bucket(for controlId: String, userId: String) -> Int
}
