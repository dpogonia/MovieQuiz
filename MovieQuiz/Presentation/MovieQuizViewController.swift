import UIKit

final class MovieQuizViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var textLabel: UILabel!
    @IBOutlet weak private var counterLabel: UILabel!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    
    // MARK: - Properties
    
    internal var currentQuestion: QuizQuestion?
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private var questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var resultAlertPresenter = ResultAlertPresenter()
    private var statisticService: StatisticServiceProtocol = StatisticService()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupQuestionFactory()
        setButtonsEnabled(true)
    }
    
    // MARK: - Setup
    
    private func setupQuestionFactory() {
        questionFactory = QuestionFactory(delegate: self)
        questionFactory?.requestNextQuestion()
    }
    
    // MARK: - Actions
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        handleAnswer(false)
    }
    
    @IBAction private func yesButtonClicked(_ sender: Any) {
        handleAnswer(true)
    }
    
    // MARK: - Question presentation
    
    func convertToView(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    // MARK: - Answer Handling
    
    private func handleAnswer(_ answer: Bool) {
        setButtonsEnabled(false)
        
        guard let currentQuestion = currentQuestion else { return }
        showResultIndicator(isCorrect: currentQuestion.correctAnswer == answer)
    }
    
    private func setButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
    
    func show(quizView step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    // MARK: - Answer UI
    
    private func showResultIndicator(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        configureImageViewBorder(isCorrect: isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showNextStep()
        }
    }
    
    private func configureImageViewBorder(isCorrect: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.cornerRadius = 20
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }
    
    // MARK: - Navigation (next quiz or result)
    
    private func showNextStep() {
        if currentQuestionIndex == questionsAmount - 1 {
            showFinalResult()
        } else {
            currentQuestionIndex += 1
            imageView.layer.borderWidth = 0
            questionFactory?.requestNextQuestion()
            setButtonsEnabled(true)
        }
    }
    
    private func showFinalResult() {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        
        let viewModel = QuizResultsViewModel(
            title: "Этот раунд окончен!",
            text: "Ваш результат: \(correctAnswers)/\(questionsAmount)",
            buttonText: "Сыграть ещё раз"
        )
        
        imageView.layer.borderWidth = 0
        show(quiz: viewModel)
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        let message = """
        \(result.text)
        Количество сыгранных квизов: \(statisticService.gamesCount)
        Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
        Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
        """
        
        let model = AlertModel(
            title: result.title,
            message: message,
            buttonText: result.buttonText
        ) { [weak self] in
            guard let self else { return }
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            self.currentQuestion = nil
            self.imageView.layer.borderWidth = 0
            self.setButtonsEnabled(true)
            self.questionFactory?.requestNextQuestion()
            
        }
        
        resultAlertPresenter.show(in: self, model: model)
    }
}
