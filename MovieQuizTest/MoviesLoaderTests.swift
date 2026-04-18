//
//  MoviesLoaderTests.swift
//  MovieQuizTest
//
//  Created by Dmitrii Pogonia on 12.04.2026.
//
import XCTest
@testable import MovieQuiz

class MoviesLoaderTests: XCTestCase {
    
    private var stubNetworkClientMock: StubNetworkClientMock!
    private var loader: MoviesLoader!
    
    override func setUp() {
        super.setUp()
        stubNetworkClientMock = StubNetworkClientMock(emulateError: false)
        loader = MoviesLoader(networkClient: stubNetworkClientMock)
    }
    
    func testSuccessLoading() throws {
        // Given
        stubNetworkClientMock = StubNetworkClientMock(emulateError: false) // говорим, что не хотим эмулировать ошибку
        loader = MoviesLoader(networkClient: stubNetworkClientMock)
        
        // When
        let expectation = expectation(description: "Loading expectation")
        
        loader.loadMovies { result in
            // Then
            switch result {
            case .success(let movies):
                // давайте проверим, что пришло, например, два фильма — ведь в тестовых данных их всего два
                XCTAssertEqual(movies.items.count, 2)
                expectation.fulfill()
            case .failure(_):
                XCTFail("Unexpected failure")
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    func testFailureLoading() throws {
        // Given
        stubNetworkClientMock = StubNetworkClientMock(emulateError: true)
        loader = MoviesLoader(networkClient: stubNetworkClientMock)
        
        // When
        let expectation = expectation(description: "Loading expectation")
        
        loader.loadMovies { result in
            // Then
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            case .success(_):
                XCTFail("Unexpected failure")
            }
        }
        waitForExpectations(timeout: 1)
    }
}



