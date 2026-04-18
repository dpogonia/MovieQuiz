//
//  ResultAlertPresenter.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 23.03.2026.
//

import UIKit

final class AlertPresenter {
    
    func show(in vc: UIViewController, model: AlertModel) {
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: model.buttonText, style: .default) { _ in
            // Важно: не выполнять completion синхронно внутри обработчика UIAlertAction.
            // Иначе dismissal/подсветка кнопки могут "залипать", если completion трогает UI/стартует загрузку.
            DispatchQueue.main.async {
                model.completion()
            }
        }
        
        alert.addAction(action)
        vc.present(alert, animated: true)
    }
}
