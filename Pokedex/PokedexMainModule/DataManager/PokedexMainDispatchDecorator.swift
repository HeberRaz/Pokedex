//
//  PokedexMainDispatchDecorator.swift
//  Pokedex
//
//  Created by Heber Alvarez on 20/03/23.
//

import Foundation

final class MainQueueDispatchDecorator: Service {

    var session: URLSessionProtocol

    private let decoratee: Service

    init(decoratee: Service) {
        self.decoratee = decoratee
        self.session = decoratee.session
    }

    func get<T: Decodable>(_ endpoint: Endpoint, callback: @escaping (Result<T,Error>) -> Void) {
        decoratee.get(endpoint) { result in
            self.guaranteeMainThread {
                callback(result)
            }
        }
    }

    func fetchImageData(urlString: String, completion: @escaping (Data?) -> Void) {
        decoratee.fetchImageData(urlString: urlString) { data in
            self.guaranteeMainThread {
                completion(data)
            }
        }
    }

    private func guaranteeMainThread(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}
