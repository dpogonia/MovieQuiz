//
//  Untitled.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 16.04.2026.
//
import UIKit

final class MovieQuizViewControllerMock: MovieQuizViewControllerProtocol {
    var lastStepModel: QuizStepModel?
    var lastResultModel: QuizResultModel?
    var isHighlightImageBorderCalled = false
    var shownNetworkErrorMessage: String?
    var isShowLoadingIndicatorCalled = false
    var isHideLoadingIndicatorCalled = false
    var isButtonsEnabled: Bool?
    
    func show(quiz step: QuizStepModel) {
        lastStepModel = step
    }
    
    func show(quiz result: QuizResultModel) {
        lastResultModel = result
    }
    
    func setButtonsEnabled(_ isEnabled: Bool) {
        isButtonsEnabled = isEnabled
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        isHighlightImageBorderCalled = true
    }
    
    func showLoadingIndicator() {
        isShowLoadingIndicatorCalled = true
    }
    
    func hideLoadingIndicator() {
        isHideLoadingIndicatorCalled = true
    }
    
    func showNetworkError(message: String) {
        shownNetworkErrorMessage = message
    }
}
