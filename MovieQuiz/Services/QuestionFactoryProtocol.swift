//
//  QuestionFactoryProtocol.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 19.03.2026.
//

import Foundation

protocol QuestionFactoryProtocol {
    var questions: [QuizQuestion] { get set }
    
    func requestNextQuestion()
}
