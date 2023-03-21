//
//  ServiceMock.swift
//  PokedexTests
//
//  Created by Heber Raziel Alvarez Ruedas on 15/11/22.
//

import Foundation
@testable import Pokedex

final class ServiceMock: Service {
    var session: URLSessionProtocol
    
    init(sessionMock: URLSessionProtocol) {
        self.session = sessionMock
    }
    
    func get<T>(_ endpoint: Endpoint, callback: @escaping (Result<T, Error>) -> Void) where T : Decodable {
        ServiceAPI(session: session).get(endpoint, callback: callback)
    }

    func fetchImageData(urlString: String, completion: @escaping (Data?) -> Void) {
        ServiceAPI(session: session).fetchImageData(urlString: urlString, completion: completion)
    }
}
