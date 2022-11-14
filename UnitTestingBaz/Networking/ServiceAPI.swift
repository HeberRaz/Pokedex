//
//  ServiceAPI.swift
//  UnitTestingBaz
//
//  Created by Heber Raziel Alvarez Ruedas on 31/10/22.
//

import Foundation

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

extension URLSession: URLSessionProtocol {
    func performDataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTaskProtocol
    }
}

class ServiceAPI: Service {
    let session: URLSessionProtocol
    
    init(session: URLSessionProtocol) {
        self.session = session
    }
    
    func get<T: Decodable>(_ endpoint: Endpoint, callback: @escaping (Result<T,Error>) -> Void) {
        let request = endpoint.request
        let task = session.performDataTask(with: request) { (data, response, error) in
            if let error: Error = error {
                callback(.failure(error))
                return
            }
            
            guard let data: Data = data else {
                callback(.failure(ServiceError.response))
                return
            }
            
            guard let response: HTTPURLResponse = response as? HTTPURLResponse else {
                callback(.failure(ServiceError.response))
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                callback(.failure(ServiceError.internalServer))
                return
            }
            
            do {
                let decodedData: T = try JSONDecoder().decode(T.self, from: data)
                callback(.success(decodedData))
            } catch {
                callback(.failure(ServiceError.parsingData))
            }
        }
        task.resume()
    }    
}
