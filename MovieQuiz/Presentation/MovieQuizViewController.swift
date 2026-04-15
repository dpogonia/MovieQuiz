import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    // MARK: - IBOutlets
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var loadingIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private var presenter: MovieQuizPresenter!
    private var alertPresenter = AlertPresenter()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        textLabel.text = ""
        counterLabel.text = ""
        presenter = MovieQuizPresenter(viewController: self)
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        
        presenter.yesButtonClicked()
        
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        
        presenter.noButtonClicked()
        
    }

    func setButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
    
    // MARK: - Correctness Indication UI
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
    }
    
    // MARK: - Network activity
    
    func showLoadingIndicator() {

        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        textLabel.text = ""
        counterLabel.text = ""
        
    }
    
    func hideLoadingIndicator() {
        
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
    }
    
    func showNetworkError(message: String) {
        
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка", message: message, buttonText: "Попробовать ещё раз") { [weak self] in
            guard let self else { return }
            self.presenter.restartGame()
        }
        
        alertPresenter.show(in: self, model: model)
    }
    
    func presentPosterLoadFailureAlert(error: Error) {
        
        hideLoadingIndicator()
        
        let model = AlertModel(
            title: "Ошибка",
            message: error.localizedDescription,
            buttonText: "Попробовать снова"
        ) { [weak self] in
            guard let self else { return }
            self.presenter.restartGame()
        }
        
        alertPresenter.show(in: self, model: model)
    }
    
    // MARK: - Navigation & Answer Handling
    
    func show(quiz step: QuizStepViewModel) {
        
        imageView.layer.cornerRadius = 20
        imageView.layer.borderColor = UIColor.clear.cgColor
        imageView.image = UIImage(data: step.image) ?? UIImage()
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }

    func show(quiz result: QuizResultsViewModel) {
        
        let message = presenter.makeResultsMessage()
        
        let model = AlertModel(
            title: result.title,
            message: message,
            buttonText: result.buttonText
        ) { [weak self] in
            guard let self else { return }
            
            self.presenter.restartGame()
            self.imageView.layer.borderColor = UIColor.clear.cgColor
        }
        
        alertPresenter.show(in: self, model: model)
    }
}
