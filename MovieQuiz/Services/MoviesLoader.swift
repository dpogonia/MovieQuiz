//
//  MoviesLoader.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 02.04.2026.
//

import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void)
}

struct MoviesLoader: MoviesLoading {
    private enum MoviesLoaderError: LocalizedError {
        case invalidURL
        case apiErrorMessage(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Некорректный URL"
            case .apiErrorMessage(let message):
                return message
            }
        }
    }

    private var top250MoviesURL: URL? {
        URL(string: "https://tv-api.com/en/API/Top250Movies/k_zcuw1ytf")
    }

    private let networkClient = NetworkClient()

    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        guard let topURL = top250MoviesURL else {
            handler(.failure(MoviesLoaderError.invalidURL))
            return
        }
        
        networkClient.fetch(url: topURL) { result in
            switch result {
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(MostPopularMovies.self, from: data)
                    if !decoded.errorMessage.isEmpty {
                        handler(.failure(MoviesLoaderError.apiErrorMessage(decoded.errorMessage)))
                        return
                    }
                    handler(.success(decoded))
                } catch {
                    handler(.failure(error))
                }
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }
}
