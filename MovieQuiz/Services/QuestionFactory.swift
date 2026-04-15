//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 18.03.2026.
//

import UIKit

private enum PosterLoadError: LocalizedError {
    
    case noMovies
    case exhaustedRetries
    
    var errorDescription: String? {
        
        switch self {
        case .noMovies:
            return "Нет фильмов для отображения."
        case .exhaustedRetries:
            return "Не удалось загрузить постер фильма. Проверьте подключение к интернету."
        }
    }
}

final class QuestionFactory: QuestionFactoryProtocol {
    
    private let moviesLoader: MoviesLoaderProtocol
    weak var delegate: QuestionFactoryDelegate?
    internal var movies: [MostPopularMovie] = []
    
    init(moviesLoader: MoviesLoaderProtocol, delegate: QuestionFactoryDelegate?) {
            self.moviesLoader = moviesLoader
            self.delegate = delegate
    }
    
    func requestNextQuestion() {
        
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            
            guard !self.movies.isEmpty else {
                DispatchQueue.main.async {
                    self.delegate?.didFailToLoadPoster(with: PosterLoadError.noMovies)
                }
                return
            }
            
            let maxAttempts = min(self.movies.count, 15)
            
            for _ in 0..<maxAttempts {
                guard let index = (0..<self.movies.count).randomElement(),
                      let movie = self.movies[safe: index] else { continue }
                guard let url = movie.resizedImageURL else { continue }
                
                do {
                    let imageData = try Data(contentsOf: url)
                    guard !imageData.isEmpty, UIImage(data: imageData) != nil else { continue }
                    
                    let rating = Float(movie.rating) ?? 0
                    let randomNum = Int.random(in: 6...9)
                    let isGreaterQuestion = Bool.random()
                    let text = "Рейтинг этого фильма \(isGreaterQuestion ? "больше" : "меньше") чем \(randomNum)?"
                    let correctAnswer = isGreaterQuestion ? (rating > Float(randomNum)) : (rating < Float(randomNum))
                    let question = QuizQuestion(image: imageData, text: text, correctAnswer: correctAnswer)
                    
                    DispatchQueue.main.async {
                        self.delegate?.didReceiveNextQuestion(question: question)
                    }
                    return
                } catch {
                    continue
                }
            }
            
            DispatchQueue.main.async {
                
                self.delegate?.didFailToLoadPoster(with: PosterLoadError.exhaustedRetries)
            }
        }
    }

    func loadData() {
        
        moviesLoader.loadMovies { [weak self] result in
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    self.movies = mostPopularMovies.items
                    self.delegate?.didLoadDataFromServer()
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }
}

