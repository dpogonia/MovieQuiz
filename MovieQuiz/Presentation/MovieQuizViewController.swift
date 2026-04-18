import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var textLabel: UILabel!
    @IBOutlet weak private var counterLabel: UILabel!
    @IBOutlet weak private var yesButton: UIButton!
    @IBOutlet weak private var noButton: UIButton!
    @IBOutlet weak private var loadingIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private var presenter: MovieQuizPresenter!
    private var alertPresenter = AlertPresenter()
    private var didStartGame = false
    private let movieLoadingView = MovieQuizLoadingView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel.text = ""
        counterLabel.text = ""
        setButtonsEnabled(false)
        setupMovieLoadingView()
        loadingIndicator.isHidden = true
        showLoadingIndicator()
    }
    
    private func setupMovieLoadingView() {
        view.addSubview(movieLoadingView)
        NSLayoutConstraint.activate([
            movieLoadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            movieLoadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            movieLoadingView.topAnchor.constraint(equalTo: view.topAnchor),
            movieLoadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !didStartGame else { return }
        didStartGame = true
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
        movieLoadingView.setAnimating(true)
        textLabel.text = ""
        counterLabel.text = ""
    }
    
    func hideLoadingIndicator() {
        movieLoadingView.setAnimating(false)
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
    
    func show(quiz step: QuizStepModel) {
        imageView.layer.cornerRadius = 20
        imageView.layer.borderColor = UIColor.clear.cgColor
        imageView.image = UIImage(data: step.image) ?? UIImage()
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }

    func show(quiz result: QuizResultModel) {
        
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
