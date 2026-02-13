//
//  RemoteConfigProviding.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//


// RemoteConfigProviding.swift

protocol RemoteConfigProviding {
    func fetchAndActivate() async throws
    func string(forKey key: String) -> String?
    func source(forKey key: String) -> RemoteConfigValueSource
}
