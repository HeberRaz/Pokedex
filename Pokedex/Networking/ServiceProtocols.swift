//
//  ServiceProtocols.swift
//  Pokedex
//
//  Created by Heber Raziel Alvarez Ruedas on 14/11/22.
//

import Foundation

protocol Service {
    var session: URLSessionProtocol { get }
    func get<T: Decodable>(_ endpoint: Endpoint, callback: @escaping (Result<T,Error>) -> Void)
    func fetchImageData(urlString: String, completion: @escaping (Data?) -> Void)
}

protocol URLSessionDataTaskProtocol {
    func resume()
}

protocol URLSessionProtocol { typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void
    func performDataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
}
