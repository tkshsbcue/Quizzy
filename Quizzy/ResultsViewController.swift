import UIKit

class ResultsViewController: UIViewController {
    
    // Data
    var mcqs: [MCQuestion] = []
    
    // UI Components
    private let mcqScrollView = UIScrollView()
    private let mcqStackView = UIStackView()
    private let saveButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayMCQs()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Generated MCQs"
        
        // MCQ ScrollView
        mcqScrollView.backgroundColor = .systemBackground
        
        // MCQ StackView
        mcqStackView.axis = .vertical
        mcqStackView.spacing = 20
        mcqStackView.alignment = .fill
        mcqStackView.distribution = .fill
        
        // Save Button
        saveButton.setTitle("Save Quiz", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Add subviews
        mcqScrollView.addSubview(mcqStackView)
        view.addSubview(mcqScrollView)
        view.addSubview(saveButton)
        
        // Setup constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        mcqScrollView.translatesAutoresizingMaskIntoConstraints = false
        mcqStackView.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Save Button
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            // MCQ ScrollView
            mcqScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mcqScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mcqScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mcqScrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20),
            
            // MCQ StackView
            mcqStackView.topAnchor.constraint(equalTo: mcqScrollView.topAnchor),
            mcqStackView.leadingAnchor.constraint(equalTo: mcqScrollView.leadingAnchor),
            mcqStackView.trailingAnchor.constraint(equalTo: mcqScrollView.trailingAnchor),
            mcqStackView.bottomAnchor.constraint(equalTo: mcqScrollView.bottomAnchor),
            mcqStackView.widthAnchor.constraint(equalTo: mcqScrollView.widthAnchor)
        ])
    }
    
    private func displayMCQs() {
        // Clear existing content first
        mcqStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Create a card for each MCQ
        for (index, mcq) in mcqs.enumerated() {
            let questionView = createQuestionView(for: mcq, number: index + 1)
            mcqStackView.addArrangedSubview(questionView)
        }
    }
    
    private func createQuestionView(for mcq: MCQuestion, number: Int) -> UIView {
        // Container for the MCQ
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.cornerRadius = 10
        
        // Question label
        let questionLabel = UILabel()
        questionLabel.text = "Q\(number): \(mcq.question)"
        questionLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        questionLabel.numberOfLines = 0
        questionLabel.textColor = .label
        
        // Options stack
        let optionsStack = UIStackView()
        optionsStack.axis = .vertical
        optionsStack.spacing = 10
        optionsStack.alignment = .fill
        optionsStack.distribution = .fillEqually
        
        // Add each option as a radio button
        for (index, option) in mcq.options.enumerated() {
            let optionView = createOptionView(option: option, isCorrect: index == mcq.correctAnswerIndex)
            optionsStack.addArrangedSubview(optionView)
        }
        
        // Add subviews to container
        containerView.addSubview(questionLabel)
        containerView.addSubview(optionsStack)
        
        // Setup constraints
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            questionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            questionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            
            optionsStack.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 15),
            optionsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            optionsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            optionsStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15)
        ])
        
        return containerView
    }
    
    private func createOptionView(option: String, isCorrect: Bool) -> UIView {
        let optionView = UIView()
        
        // Radio button
        let radioButton = UIButton(type: .custom)
        radioButton.setImage(UIImage(systemName: "circle"), for: .normal)
        radioButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        radioButton.tintColor = isCorrect ? .systemGreen : .systemBlue
        radioButton.isSelected = isCorrect
        radioButton.isUserInteractionEnabled = false
        
        // Option label
        let optionLabel = UILabel()
        optionLabel.text = option
        optionLabel.font = UIFont.systemFont(ofSize: 16)
        optionLabel.numberOfLines = 0
        optionLabel.textColor = .label
        
        // Add subviews
        optionView.addSubview(radioButton)
        optionView.addSubview(optionLabel)
        
        // Setup constraints
        radioButton.translatesAutoresizingMaskIntoConstraints = false
        optionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            radioButton.leadingAnchor.constraint(equalTo: optionView.leadingAnchor),
            radioButton.centerYAnchor.constraint(equalTo: optionView.centerYAnchor),
            radioButton.widthAnchor.constraint(equalToConstant: 24),
            radioButton.heightAnchor.constraint(equalToConstant: 24),
            
            optionLabel.leadingAnchor.constraint(equalTo: radioButton.trailingAnchor, constant: 10),
            optionLabel.trailingAnchor.constraint(equalTo: optionView.trailingAnchor),
            optionLabel.topAnchor.constraint(equalTo: optionView.topAnchor),
            optionLabel.bottomAnchor.constraint(equalTo: optionView.bottomAnchor)
        ])
        
        return optionView
    }
    
    @objc private func saveButtonTapped() {
        // In a real app, this would save the quiz to persistent storage
        let alert = UIAlertController(
            title: "Quiz Saved",
            message: "Your quiz has been saved successfully!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }
} 