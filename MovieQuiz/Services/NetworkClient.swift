//
//  NetworkClient.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 02.04.2026.
//

import Foundation

struct NetworkClient {
    
    enum NetworkError: Error {
        case transport(Error)
        case notHTTPResponse
        case httpStatusCode(Int)
        case noData
    }
    
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                handler(.failure(NetworkError.transport(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                handler(.failure(NetworkError.notHTTPResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                handler(.failure(NetworkError.httpStatusCode(httpResponse.statusCode)))
                return
            }

            guard let data else {
                handler(.failure(NetworkError.noData))
                return
            }
            
            handler(.success(data))
        }
        task.resume()
    }
}
