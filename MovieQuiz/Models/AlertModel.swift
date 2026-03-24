//
//  AlertModel.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 23.03.2026.
//

import UIKit

struct AlertModel {
    var title: String
    var message: String
    var buttonText: String
    var completion: () -> Void
}
