//
//  QuestionFactoryProtocol.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 19.03.2026.
//

import Foundation

protocol QuestionFactoryProtocol {
    
    var movies: [MostPopularMovie] { get set }
    func requestNextQuestion()
    func loadData()
}
