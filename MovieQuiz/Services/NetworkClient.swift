//
//  NetworkClient.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 02.04.2026.
//

import Foundation

protocol NetworkRoutingProtocol {
    
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void)
}

struct NetworkClient: NetworkRoutingProtocol {
    
    enum NetworkError: Error {
        case transport(Error)
        case notHTTPResponse
        case httpStatusCode(Int)
        case noData
    }
    
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        
        var request = URLRequest(url: url)
        // Быстро переключаемся на fallback при недоступном API.
        // У URLSession.shared дефолтный timeout для запроса ~60 секунд.
        request.timeoutInterval = 5
        
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

extension NetworkClient.NetworkError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .transport:
            return "Не удалось выполнить запрос. Проверьте подключение к интернету."
        case .notHTTPResponse:
            return "Некорректный ответ сервера."
        case .httpStatusCode(let code):
            return "Сервер вернул ошибку (код \(code))."
        case .noData:
            return "Данные не получены."
        }
    }
}
