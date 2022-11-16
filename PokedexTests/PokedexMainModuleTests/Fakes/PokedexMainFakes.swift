//
//  PokedexMainFakes.swift
//  PokedexTests
//
//  Created by Heber Raziel Alvarez Ruedas on 16/11/22.
//

import Foundation

class PokedexMainFakes {
    var pokemonBlock: Data { getDataFrom(json: "pokemonBlock") }
    
    // MARK: - Private methods
    private func getDataFrom(json file: String) -> Data {
        guard let path: String = Bundle(for: type(of: self)).path(forResource: file, ofType: "json") else {
            fatalError("El archivo seleccionado no se encontró")
        }
        let data: Data = try! Data(contentsOf: URL(fileURLWithPath: path))
        return data
    }
}
