//
//  MovieQuizViewControllerProtocol.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 15.04.2026.
//

import UIKit

protocol MovieQuizViewControllerProtocol: AnyObject {
    
    func show(quiz step: QuizStepViewModel)
    func show(quiz result: QuizResultsViewModel)
    
    func setButtonsEnabled(_ isEnabled: Bool)
    func highlightImageBorder(isCorrectAnswer: Bool)
    
    func showLoadingIndicator()
    func hideLoadingIndicator()
    
    func showNetworkError(message: String)
}
