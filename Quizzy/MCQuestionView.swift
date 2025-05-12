import UIKit

class MCQuestionView: UIView {
    
    // UI Components
    private let containerView = UIView()
    private let questionLabel = UILabel()
    private let optionsStackView = UIStackView()
    private var optionButtons: [UIButton] = []
    
    // Data
    private var question: String = ""
    private var options: [String] = []
    private var correctAnswerIndex: Int?
    
    // Callback
    var onOptionSelected: ((Int) -> Void)?
    
    // Initialize with frame
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Container view styling
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 6
        
        // Question label styling
        questionLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        questionLabel.textColor = .quizzyTextDark
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .left
        
        // Options stack view styling
        optionsStackView.axis = .vertical
        optionsStackView.spacing = 12
        optionsStackView.alignment = .fill
        optionsStackView.distribution = .fillEqually
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(questionLabel)
        containerView.addSubview(optionsStackView)
        
        // Setup constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Question label
            questionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            questionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            questionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Options stack view
            optionsStackView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 16),
            optionsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            optionsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            optionsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // Configure the view with question data
    func configure(with question: String, options: [String], correctAnswerIndex: Int? = nil) {
        self.question = question
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
        
        // Setup question text
        questionLabel.text = question
        
        // Clear previous options if any
        optionButtons.forEach { $0.removeFromSuperview() }
        optionButtons.removeAll()
        
        // Create option buttons
        for (index, option) in options.enumerated() {
            let optionButton = createOptionButton(option: option, index: index)
            optionsStackView.addArrangedSubview(optionButton)
            optionButtons.append(optionButton)
        }
    }
    
    private func createOptionButton(option: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        
        // Use option index to create alphabetic option (A, B, C, D)
        let optionLetter = String(UnicodeScalar(65 + index)!)
        
        // Create an attributed string with the option letter in bold
        let fullText = "\(optionLetter). \(option)"
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // Apply bold attribute to the option letter part
        attributedString.addAttribute(.font, 
                                     value: UIFont.systemFont(ofSize: 16, weight: .bold), 
                                     range: NSRange(location: 0, length: 2))
        
        // Rest of the text with regular weight
        attributedString.addAttribute(.font, 
                                     value: UIFont.systemFont(ofSize: 16, weight: .regular), 
                                     range: NSRange(location: 2, length: fullText.count - 2))
        
        // Apply the attributed string to the button
        button.setAttributedTitle(attributedString, for: .normal)
        button.setTitleColor(.quizzyTextDark, for: .normal)
        
        // Style the button
        button.backgroundColor = .quizzyBackground
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        
        // Add tap action
        button.tag = index
        button.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside)
        
        // Setup constraints
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }
    
    @objc private func optionButtonTapped(_ sender: UIButton) {
        // Reset all buttons to default state
        optionButtons.forEach { button in
            button.backgroundColor = .quizzyBackground
            button.setTitleColor(.quizzyTextDark, for: .normal)
        }
        
        // Highlight the selected button
        sender.backgroundColor = .quizzyPrimary
        sender.setTitleColor(.white, for: .normal)
        
        // If correct answer index is provided, show right/wrong feedback
        if let correctIndex = correctAnswerIndex {
            if sender.tag == correctIndex {
                // Correct answer
                sender.backgroundColor = .quizzySuccessGreen
            } else {
                // Wrong answer - show the correct one too
                sender.backgroundColor = .quizzyErrorRed
                optionButtons[correctIndex].backgroundColor = .quizzySuccessGreen
                optionButtons[correctIndex].setTitleColor(.white, for: .normal)
            }
        }
        
        // Call the callback with the selected index
        onOptionSelected?(sender.tag)
    }
} 