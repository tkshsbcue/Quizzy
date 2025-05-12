import UIKit

class ResultsViewController: UIViewController {
    
    // Data
    var mcqs: [MCQuestion] = []
    private var userSelections: [Int: Int] = [:] // [QuestionIndex: SelectedOptionIndex]
    
    // UI Components
    private let mcqScrollView = UIScrollView()
    private let mcqStackView = UIStackView()
    private let submitButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    
    // State
    private var hasSubmitted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayMCQs()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Quiz"
        
        // MCQ ScrollView
        mcqScrollView.backgroundColor = .systemBackground
        
        // MCQ StackView
        mcqStackView.axis = .vertical
        mcqStackView.spacing = 20
        mcqStackView.alignment = .fill
        mcqStackView.distribution = .fill
        
        // Submit Button
        submitButton.setTitle("Submit Answers", for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        submitButton.backgroundColor = .systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 10
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        
        // Save Button
        saveButton.setTitle("Save Quiz", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        saveButton.isHidden = true // Hidden until quiz is submitted
        
        // Add subviews
        mcqScrollView.addSubview(mcqStackView)
        view.addSubview(mcqScrollView)
        view.addSubview(submitButton)
        view.addSubview(saveButton)
        
        // Setup constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        mcqScrollView.translatesAutoresizingMaskIntoConstraints = false
        mcqStackView.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Submit Button
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Save Button - same position as submit button, will be shown after submission
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            // MCQ ScrollView
            mcqScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mcqScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mcqScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mcqScrollView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -20),
            
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
            let questionView = createQuestionView(for: mcq, number: index)
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
        containerView.tag = number // Store question index in tag
        
        // Question label
        let questionLabel = UILabel()
        questionLabel.text = "Q\(number + 1): \(mcq.question)"
        questionLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        questionLabel.numberOfLines = 0
        questionLabel.textColor = .label
        
        // Options stack
        let optionsStack = UIStackView()
        optionsStack.axis = .vertical
        optionsStack.spacing = 10
        optionsStack.alignment = .fill
        optionsStack.distribution = .fillEqually
        optionsStack.tag = 100 // Tag to identify the options stack
        
        // Add each option as a radio button
        for (index, option) in mcq.options.enumerated() {
            let optionView = createOptionView(option: option, 
                                             optionIndex: index, 
                                             questionIndex: number)
            optionsStack.addArrangedSubview(optionView)
        }
        
        // Result label (initially hidden)
        let resultLabel = UILabel()
        resultLabel.text = ""
        resultLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0
        resultLabel.isHidden = true
        resultLabel.tag = 200 // Tag to identify the result label
        
        // Add subviews to container
        containerView.addSubview(questionLabel)
        containerView.addSubview(optionsStack)
        containerView.addSubview(resultLabel)
        
        // Setup constraints
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            questionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            questionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            
            optionsStack.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 15),
            optionsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            optionsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            
            resultLabel.topAnchor.constraint(equalTo: optionsStack.bottomAnchor, constant: 10),
            resultLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            resultLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            resultLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15)
        ])
        
        return containerView
    }
    
    private func createOptionView(option: String, optionIndex: Int, questionIndex: Int) -> UIView {
        let optionView = UIView()
        
        // Radio button
        let radioButton = UIButton(type: .custom)
        radioButton.setImage(UIImage(systemName: "circle"), for: .normal)
        radioButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        radioButton.tintColor = .systemBlue
        radioButton.isSelected = false
        radioButton.tag = optionIndex
        
        // Enable user interaction
        radioButton.isUserInteractionEnabled = true
        radioButton.addTarget(self, action: #selector(optionSelected(_:)), for: .touchUpInside)
        
        // Store question index in accessibilityIdentifier for retrieval in the action method
        radioButton.accessibilityIdentifier = "\(questionIndex)"
        
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
    
    @objc private func optionSelected(_ sender: UIButton) {
        // Ignore selection if already submitted
        if hasSubmitted {
            return
        }
        
        guard let questionIndexStr = sender.accessibilityIdentifier,
              let questionIndex = Int(questionIndexStr) else {
            return
        }
        
        // Find the container view and options stack
        guard let optionView = sender.superview,
              let containerView = optionView.superview?.superview,
              let optionsStack = containerView.viewWithTag(100) as? UIStackView else {
            return
        }
        
        // Deselect all other options in this question
        for arrangedSubview in optionsStack.arrangedSubviews {
            for subview in arrangedSubview.subviews {
                if let button = subview as? UIButton {
                    button.isSelected = (button == sender)
                }
            }
        }
        
        // Store user's selection
        userSelections[questionIndex] = sender.tag
    }
    
    @objc private func submitButtonTapped() {
        // Check if user answered all questions
        let answeredCount = userSelections.count
        if answeredCount < mcqs.count {
            let alert = UIAlertController(
                title: "Incomplete",
                message: "You've answered \(answeredCount) of \(mcqs.count) questions. Are you sure you want to submit?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Submit Anyway", style: .default) { [weak self] _ in
                self?.gradeQuiz()
            })
            
            alert.addAction(UIAlertAction(title: "Continue Quiz", style: .cancel))
            
            present(alert, animated: true)
        } else {
            gradeQuiz()
        }
    }
    
    private func gradeQuiz() {
        hasSubmitted = true
        
        // Calculate score
        var correctAnswers = 0
        var totalAnswered = 0
        
        for (questionIndex, selectedOptionIndex) in userSelections {
            let correctOptionIndex = mcqs[questionIndex].correctAnswerIndex
            let isCorrect = (selectedOptionIndex == correctOptionIndex)
            
            // Update UI to show correct/incorrect
            guard questionIndex < mcqStackView.arrangedSubviews.count else { continue }
            let containerView = mcqStackView.arrangedSubviews[questionIndex]
            
            // Show result label
            if let resultLabel = containerView.viewWithTag(200) as? UILabel {
                resultLabel.isHidden = false
                
                if isCorrect {
                    resultLabel.text = "Correct!"
                    resultLabel.textColor = .systemGreen
                } else {
                    resultLabel.text = "Incorrect. The correct answer is option \(Character(UnicodeScalar(65 + correctOptionIndex)!))."
                    resultLabel.textColor = .systemRed
                }
            }
            
            // Update option button colors
            if let optionsStack = containerView.viewWithTag(100) as? UIStackView {
                for case let optionView as UIView in optionsStack.arrangedSubviews {
                    for subview in optionView.subviews {
                        if let button = subview as? UIButton {
                            let optionIndex = button.tag
                            
                            if optionIndex == correctOptionIndex {
                                // Correct answer
                                button.tintColor = .systemGreen
                            } else if optionIndex == selectedOptionIndex {
                                // User's incorrect selection
                                button.tintColor = isCorrect ? .systemGreen : .systemRed
                            } else {
                                // Other options
                                button.tintColor = .systemGray
                            }
                        }
                    }
                }
            }
            
            if isCorrect {
                correctAnswers += 1
            }
            totalAnswered += 1
        }
        
        // Calculate percentage score
        let percentage = (totalAnswered > 0) ? Double(correctAnswers) / Double(totalAnswered) * 100 : 0
        
        // Show score alert
        let alert = UIAlertController(
            title: "Quiz Results",
            message: "You scored \(correctAnswers)/\(totalAnswered) (\(Int(percentage))%)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
        
        // Switch buttons
        submitButton.isHidden = true
        saveButton.isHidden = false
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