//
//  RemoteConfigValueSource.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//

import Foundation

enum RemoteConfigValueSource: String, Sendable {
    case remote
    case `default`
    case `static`
    case unknown
}
