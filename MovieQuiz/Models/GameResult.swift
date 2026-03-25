//
//  GameResult.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 24.03.2026.
//

import UIKit

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date
    
    func isBetterThan(newResult: GameResult) -> Bool {
        correct > newResult.correct
    }
}
