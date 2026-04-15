//
//  MovieQuizPresenter.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 14.04.2026.
//

import UIKit

// MARK: - Question presentation

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    private let statisticService: StatisticServiceProtocol
    private var questionFactory: QuestionFactoryProtocol?
    private weak var viewController: MovieQuizViewControllerProtocol?
    
    private var currentQuestion: QuizQuestion?
    private(set) var questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    private(set) var correctAnswers = 0
    
    init(viewController: MovieQuizViewControllerProtocol) {
        
        self.viewController = viewController
        self.statisticService = StatisticService()
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
    
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    // MARK: - Обработка кнопок
    
    func yesButtonClicked() {
        
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        
        didAnswer(isYes: false)
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = isYes
        proceedWithAnswer(isCorrectAnswer: givenAnswer == currentQuestion.correctAnswer)
    }

    func didAnswer(isCorrectAnswer: Bool) {
        
        if isCorrectAnswer {
            correctAnswers += 1
        }
    }

    func proceedWithAnswer(isCorrectAnswer: Bool) {
        
        viewController?.setButtonsEnabled(false)
        didAnswer(isCorrectAnswer: isCorrectAnswer)
        
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrectAnswer)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            
            guard let self else { return }
            
            self.proceedToNextQuestionOrResults()
        }
    }
    
    // MARK: - Переходы
    
    func isLastQuestion() -> Bool {
        
        currentQuestionIndex == questionsAmount - 1
    }
    
    func restartGame() {
        
        currentQuestionIndex = 0
        correctAnswers = 0
        currentQuestion = nil
        
        viewController?.showLoadingIndicator()
        questionFactory?.loadData()
    }
    
    func switchToNextQuestion() {
        
        currentQuestionIndex += 1
    }
    
    func proceedToNextQuestionOrResults() {
        
        if isLastQuestion() {
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: "Ваш результат: \(correctAnswers)/\(questionsAmount)",
                buttonText: "Сыграть ещё раз"
            )
            viewController?.show(quiz: viewModel)
        } else {
            
            switchToNextQuestion()
            viewController?.showLoadingIndicator()
            questionFactory?.requestNextQuestion()
        }
    }
    
    // MARK: - Создание карточек вопросов
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        
        guard let question = question else { return }
        
        currentQuestion = question
        _ = convert(model: question)
        viewController?.setButtonsEnabled(true)
        
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.hideLoadingIndicator()
        }
    }
    
    func didFailToLoadPoster(with error: Error) {
        viewController?.hideLoadingIndicator()
        viewController?.showNetworkError(message: error.localizedDescription)
    }
    
    func didLoadDataFromServer() {
        
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        
        viewController?.hideLoadingIndicator()
        viewController?.showNetworkError(message: error.localizedDescription)
    }
    
    func makeResultsMessage() -> String {
        
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        
        let bestGame = statisticService.bestGame
        
        let totalPlaysCountLine = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let currentGameResultLine = "Ваш результат: \(correctAnswers)/\(questionsAmount)"
        let bestGameInfoLine = "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))"
        let averageAccuracyLine = "Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%"
        
        return [
            currentGameResultLine,
            totalPlaysCountLine,
            bestGameInfoLine,
            averageAccuracyLine
        ].joined(separator: "\n")
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        
        let viewModel = QuizStepViewModel(
            image: model.image,
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
        
        viewController?.show(quiz: viewModel)
        
        return viewModel
    }
}
