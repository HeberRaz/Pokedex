//
//  ServiceError.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 14/11/22.
//

import Foundation

enum ServiceError: Error {
    case noData
    case response
    case parsingData
    case internalServer
}
