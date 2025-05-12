import UIKit

class ResultsViewController: UIViewController {
    
    // Data
    var mcqs: [MCQuestion] = []
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let questionsStackView = UIStackView()
    private let saveButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Set up the view
        view.backgroundColor = .quizzyBackground
        title = "Quiz Results"
        
        // Setup content view
        contentView.backgroundColor = .clear
        
        // Setup scroll view
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        // Setup questions stack view
        questionsStackView.axis = .vertical
        questionsStackView.spacing = 24
        questionsStackView.alignment = .fill
        questionsStackView.distribution = .equalSpacing
        
        // Setup save button
        saveButton.setTitle("Save Quiz", for: .normal)
        saveButton.backgroundColor = .quizzyPrimary
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 16
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        saveButton.layer.shadowColor = UIColor.black.cgColor
        saveButton.layer.shadowOpacity = 0.15
        saveButton.layer.shadowRadius = 8
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(questionsStackView)
        view.addSubview(saveButton)
        
        // Setup constraints
        setupConstraints()
        
        // Populate with MCQs
        populateQuestionsStackView()
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        questionsStackView.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Save Button
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Questions Stack View
            questionsStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            questionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            questionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            questionsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func populateQuestionsStackView() {
        // Clear existing content first
        questionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Create MCQuestionView for each MCQ
        for (index, mcq) in mcqs.enumerated() {
            let questionView = createQuestionView(for: mcq, number: index + 1)
            questionsStackView.addArrangedSubview(questionView)
        }
    }
    
    private func createQuestionView(for mcq: MCQuestion, number: Int) -> UIView {
        // Create our custom MCQuestionView with numbered question
        let mcqView = MCQuestionView(frame: .zero)
        
        // Add question number to the question
        let numberedQuestion = "Question \(number): \(mcq.question)"
        
        // Configure the MCQuestionView
        mcqView.configure(with: numberedQuestion, options: mcq.options, correctAnswerIndex: mcq.correctAnswerIndex)
        
        return mcqView
    }
    
    @objc private func saveButtonTapped() {
        let alert = UIAlertController(
            title: "Quiz Saved",
            message: "Your quiz has been saved successfully.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }
} 