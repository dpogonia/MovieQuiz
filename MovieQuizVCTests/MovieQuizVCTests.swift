//
//  MovieQuizVCTests.swift
//  MovieQuizVCTests
//
//  Created by Dmitrii Pogonia on 15.04.2026.
//

import XCTest
@testable import MovieQuiz

final class MovieQuizViewControllerMock: MovieQuizViewControllerProtocol {
    var lastStepModel: QuizStepViewModel?
    var lastResultModel: QuizResultsViewModel?
    var isHighlightImageBorderCalled = false
    var shownNetworkErrorMessage: String?
    var isShowLoadingIndicatorCalled = false
    var isHideLoadingIndicatorCalled = false
    var isButtonsEnabled: Bool?
    
    func show(quiz step: QuizStepViewModel) {
        lastStepModel = step
    }
    
    func show(quiz result: QuizResultsViewModel) {
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

final class MovieQuizPresenterTests: XCTestCase {
    func testPresenterConvertModel() throws {
        let viewControllerMock = MovieQuizViewControllerMock()
        let sut = MovieQuizPresenter(viewController: viewControllerMock)
        
        let emptyData = Data()
        let question = QuizQuestion(image: emptyData, text: "Question Text", correctAnswer: true)
        let viewModel = sut.convert(model: question)
        
        XCTAssertEqual(viewControllerMock.lastStepModel?.image, emptyData)
        XCTAssertEqual(viewModel.question, "Question Text")
        XCTAssertEqual(viewModel.questionNumber, "1/10")
    }
}
