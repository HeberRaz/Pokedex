//
//  RemoteConfigValuePolicy.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//


enum RemoteConfigValuePolicy: Sendable {
    /// Acepta valores que vengan del server o defaults locales
    case acceptRemoteOrDefault
    /// Acepta únicamente valores que vengan del server (Firebase Console)
    case acceptRemoteOnly
}