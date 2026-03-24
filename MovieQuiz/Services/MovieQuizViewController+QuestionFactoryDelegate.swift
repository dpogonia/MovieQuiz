//
//  MovieQuizViewController+QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 23.03.2026.
//

import UIKit

extension MovieQuizViewController: QuestionFactoryDelegate {
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        
        currentQuestion = question
        let viewModel = convertToVM(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
}

