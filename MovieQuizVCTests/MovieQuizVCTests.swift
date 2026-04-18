//
//  MovieQuizVCTests.swift
//  MovieQuizVCTests
//
//  Created by Dmitrii Pogonia on 15.04.2026.
//

import XCTest
@testable import MovieQuiz

final class MovieQuizPresenterTests: XCTestCase {
    
    func testPresenterConvertModel() throws {
        // Given
        let viewControllerMock = MovieQuizViewControllerMock()
        let sut = MovieQuizPresenter(viewController: viewControllerMock)
        
        let emptyData = Data()
        let question = QuizQuestion(image: emptyData, text: "Question Text", correctAnswer: true)
        
        // When
        let viewModel = sut.convert(model: question)
        
        // Then
        XCTAssertEqual(viewControllerMock.lastStepModel?.image, emptyData)
        XCTAssertEqual(viewModel.question, "Question Text")
        XCTAssertEqual(viewModel.questionNumber, "1/10")
    }
}
