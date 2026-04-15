//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 19.03.2026.
//

import Foundation

protocol QuestionFactoryDelegate: AnyObject {
    
    func didReceiveNextQuestion(question: QuizQuestion?)
    func didLoadDataFromServer()
    func didFailToLoadData(with error: Error)
    func didFailToLoadPoster(with error: Error)
}
