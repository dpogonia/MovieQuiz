//
//  MovieQuizUITests.swift
//  MovieQuizUITests
//
//  Created by Dmitrii Pogonia on 12.04.2026.
//

import XCTest

final class MovieQuizUITests: XCTestCase {
    
    var app: XCUIApplication!
    private let defaultTimeout: TimeInterval = 15

    override func setUpWithError() throws {
        try super.setUpWithError()
        app = XCUIApplication()
        app.launch()
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        app.terminate()
        app = nil
    }
    
    func testYesButton() {
        /*
        // Старый код опирается на фиксированные sleep(),
        // но после рефакторинга загрузка/переходы стали асинхронными и по времени нестабильны, поэтому закомментировал старый вариант
        sleep(3)

        let firstPoster = app.images["Poster"]
        let firstPosterData = firstPoster.screenshot().pngRepresentation

        app.buttons["Yes"].tap()
        sleep(3)

        let secondPoster = app.images["Poster"]
        let secondPosterData = secondPoster.screenshot().pngRepresentation

        let indexLabel = app.staticTexts["indexLabel"]

        XCTAssertNotEqual(firstPosterData, secondPosterData)
        XCTAssertEqual(indexLabel.label, "2/10")
        */
        
        let poster = app.images["Poster"]
        let indexLabel = app.staticTexts["indexLabel"]
        
        waitForExists(poster)
        waitForLabel(indexLabel, equals: "1/10")
        let firstPosterData = poster.screenshot().pngRepresentation
        
        app.buttons["Yes"].tap()
        waitForLabel(indexLabel, equals: "2/10")
        let secondPosterData = poster.screenshot().pngRepresentation
        
        XCTAssertNotEqual(firstPosterData, secondPosterData)
    }
    
    func testNoButton() {
        /*
        // Старый код (флейки): фиксированный sleep() не гарантирует,
        // что следующий вопрос уже загрузился и показан.
        sleep(3)

        let firstPoster = app.images["Poster"]
        let firstPosterData = firstPoster.screenshot().pngRepresentation

        app.buttons["No"].tap()
        sleep(3)

        let secondPoster = app.images["Poster"]
        let secondPosterData = secondPoster.screenshot().pngRepresentation

        let indexLabel = app.staticTexts["indexLabel"]

        XCTAssertNotEqual(firstPosterData, secondPosterData)
        XCTAssertEqual(indexLabel.label, "2/10")
        */
        
        let poster = app.images["Poster"]
        let indexLabel = app.staticTexts["indexLabel"]
        
        waitForExists(poster)
        waitForLabel(indexLabel, equals: "1/10")
        let firstPosterData = poster.screenshot().pngRepresentation
        
        app.buttons["No"].tap()
        waitForLabel(indexLabel, equals: "2/10")
        let secondPosterData = poster.screenshot().pngRepresentation
        
        XCTAssertNotEqual(firstPosterData, secondPosterData)
    }
    
    func testGameFinish() {
        /*
        // Старый код (флейки): часть тапов может попадать в момент,
        // когда кнопки disabled (подсветка/переход), и игра не доходит до финиша.
        sleep(2)
        for _ in 1...10 {
            app.buttons["No"].tap()
            sleep(2)
        }

        let alert = app.alerts["Этот раунд окончен!"]

        XCTAssertTrue(alert.exists)
        XCTAssertTrue(alert.label == "Этот раунд окончен!")
        XCTAssertTrue(alert.buttons.firstMatch.label == "Сыграть ещё раз")
        */
        
        let indexLabel = app.staticTexts["indexLabel"]
        waitForLabel(indexLabel, equals: "1/10")
        
        // Нажимаем 9 раз, каждый раз ждём, что индекс вопроса увеличился.
        // Затем отвечаем на 10-й вопрос, после чего должен появиться алерт с результатом.
        if questionsTotal() == 10 {
            for expected in 2...10 {
                app.buttons["No"].tap()
                waitForLabel(indexLabel, equals: "\(expected)/10")
            }
            // Ответ на последний (10-й) вопрос
            app.buttons["No"].tap()
        } else {
            // Если в будущем количество вопросов изменят, тест останется логически корректным.
            for expected in 2...questionsTotal() {
                app.buttons["No"].tap()
                waitForLabel(indexLabel, equals: "\(expected)/\(questionsTotal())")
            }
            // Ответ на последний вопрос
            app.buttons["No"].tap()
        }
        
        let alert = app.alerts["Этот раунд окончен!"]
        waitForExists(alert)
        
        XCTAssertEqual(alert.label, "Этот раунд окончен!")
        XCTAssertEqual(alert.buttons["Сыграть ещё раз"].label, "Сыграть ещё раз")
    }

    func testAlertDismiss() {
        /*
        // Старый код (флейки): алерт может не появиться к моменту поиска,
        // а firstMatch.tap() упадёт, если алерта ещё нет.
        sleep(2)
        for _ in 1...10 {
            app.buttons["No"].tap()
            sleep(2)
        }

        let alert = app.alerts["Этот раунд окончен!"]
        alert.buttons.firstMatch.tap()

        sleep(2)

        let indexLabel = app.staticTexts["indexLabel"]

        XCTAssertFalse(alert.exists)
        XCTAssertTrue(indexLabel.label == "1/10")
        */
        
        let indexLabel = app.staticTexts["indexLabel"]
        waitForLabel(indexLabel, equals: "1/10")
        
        if questionsTotal() == 10 {
            for expected in 2...10 {
                app.buttons["No"].tap()
                waitForLabel(indexLabel, equals: "\(expected)/10")
            }
            // Ответ на последний (10-й) вопрос
            app.buttons["No"].tap()
        } else {
            for expected in 2...questionsTotal() {
                app.buttons["No"].tap()
                waitForLabel(indexLabel, equals: "\(expected)/\(questionsTotal())")
            }
            // Ответ на последний вопрос
            app.buttons["No"].tap()
        }
        
        let alert = app.alerts["Этот раунд окончен!"]
        waitForExists(alert)
        alert.buttons["Сыграть ещё раз"].tap()
        
        waitForNotExists(alert)
        waitForLabel(indexLabel, equals: "1/10")
        
    }
    
    // MARK: - Helpers
    
    private func waitForExists(_ element: XCUIElement, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let ok = element.waitForExistence(timeout: timeout ?? defaultTimeout)
        XCTAssertTrue(ok, "Element did not appear in time: \(element)", file: file, line: line)
    }
    
    private func waitForNotExists(_ element: XCUIElement, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == false")
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [exp], timeout: timeout ?? defaultTimeout)
        XCTAssertEqual(result, .completed, "Element still exists after timeout: \(element)", file: file, line: line)
    }
    
    private func waitForLabel(_ element: XCUIElement, equals expected: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        waitForExists(element, timeout: timeout ?? defaultTimeout, file: file, line: line)
        let predicate = NSPredicate(format: "label == %@", expected)
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [exp], timeout: timeout ?? defaultTimeout)
        XCTAssertEqual(result, .completed, "Label didn't become '\(expected)'. Actual: '\(element.label)'", file: file, line: line)
    }
    
    // Если когда-нибудь в UI изменят формат счётчика, достаточно поправить парсер тут.
    private func questionsTotal() -> Int {
        let indexLabel = app.staticTexts["indexLabel"]
        if indexLabel.exists {
            let parts = indexLabel.label.split(separator: "/")
            if parts.count == 2, let total = Int(parts[1]) {
                return total
            }
        }
        return 10
    }
}
