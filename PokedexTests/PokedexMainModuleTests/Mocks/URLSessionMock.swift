//
//  URLSessionMock.swift
//  PokedexTests
//
//  Created by Heber Raziel Alvarez Ruedas on 15/11/22.
//

import Foundation
@testable import Pokedex

final class URLSessionMock: URLSessionProtocol {
    var data: Data?
    var urlResponse: URLResponse?
    var error: Error?
    
    var dataTask = URLSessionDataTaskDummy()
    
    func performDataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        completionHandler(data, urlResponse, error)
        return dataTask
    }
}

class URLSessionDataTaskDummy: URLSessionDataTaskProtocol {
    func resume() {}
}
