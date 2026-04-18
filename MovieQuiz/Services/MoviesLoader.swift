//
//  MoviesLoader.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 02.04.2026.
//

import Foundation

// MARK: - Protocol

protocol MoviesLoaderProtocol {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void)
}

// MARK: - MoviesLoader

struct MoviesLoader: MoviesLoaderProtocol {
    
    // MARK: - Errors
    
    private enum MoviesLoaderError: LocalizedError {
        case invalidURL
        case emptyResponse
        case apiErrorMessage(String)
        case emptyMovieList
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Некорректный URL"
            case .emptyResponse:
                return "Пустой ответ сервера"
            case .apiErrorMessage(let message):
                return message
            case .emptyMovieList:
                return "Список фильмов пуст"
            }
        }
    }
    
    // MARK: - Properties

    private var top250MoviesURL: URL? {
        URL(string: "https://tv-api.com/en/API/Top250Movies/k_zcuw1ytf")
    }

    private let networkClient: NetworkRoutingProtocol
    
    init(networkClient: NetworkRoutingProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    // MARK: - Public Methods

    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        guard let topURL = top250MoviesURL else {
            handler(.failure(MoviesLoaderError.invalidURL))
            return
        }
        
        networkClient.fetch(url: topURL) { result in
            switch result {
            case .success(let data):
                guard !data.isEmpty else {
                    handler(.failure(MoviesLoaderError.emptyResponse))
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(MostPopularMovies.self, from: data)
                    let apiMessage = decoded.errorMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !apiMessage.isEmpty {
                        handler(.failure(MoviesLoaderError.apiErrorMessage(apiMessage)))
                        return
                    }
                    guard !decoded.items.isEmpty else {
                        handler(.failure(MoviesLoaderError.emptyMovieList))
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
