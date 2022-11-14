//
//  Endpoint.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import Foundation

enum Endpoint {
    static let baseURL = "https://pokeapi.co/api/v2/pokemon/"
    
    case next(urlString: String)
    case pokemon(nameOrId: String)
}

extension Endpoint {
    var string: String {
        switch self {
        case .next(urlString: let string):
            return string
        case .pokemon(let nameOrId):
            return "\(nameOrId)"
        }
    }
    
    var request: URLRequest {
        switch self {
        case .next(urlString: let string):
            let url: URL = URL(string: string) ?? URL(fileURLWithPath: "")
            return URLRequest(url: url)
        case .pokemon:
            let url: URL = URL(string: Endpoint.baseURL + string) ?? URL(fileURLWithPath: "")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            return request
        }
    }
}
