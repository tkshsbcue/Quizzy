import UIKit
import PDFKit

class ViewController: UIViewController {
    
    // UI Components
    private let uploadButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let mcqContainerView = UIView()
    private let mcqScrollView = UIScrollView()
    private let mcqStackView = UIStackView()
    
    // PDF Content
    private var pdfContent: String?
    private var documentPicker: UIDocumentPickerViewController?
    
    // Gemini API Client
    private let geminiClient = GeminiAPIClient(apiKey: "AIzaSyDWAko1bg-foCoARm5VmUIMTyPvhidQtIE")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "PDF to MCQ Generator"
        
        // Upload Button
        uploadButton.setTitle("Upload PDF", for: .normal)
        uploadButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        uploadButton.backgroundColor = .systemBlue
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.layer.cornerRadius = 10
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        
        // Status Label
        statusLabel.text = "Upload a PDF to generate MCQs"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .secondaryLabel
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        
        // MCQ Container
        mcqContainerView.backgroundColor = .systemBackground
        mcqContainerView.layer.borderColor = UIColor.systemGray4.cgColor
        mcqContainerView.layer.borderWidth = 1
        mcqContainerView.layer.cornerRadius = 10
        mcqContainerView.isHidden = true
        
        // MCQ ScrollView and StackView
        mcqStackView.axis = .vertical
        mcqStackView.spacing = 20
        mcqStackView.alignment = .fill
        mcqStackView.distribution = .fill
        mcqScrollView.addSubview(mcqStackView)
        mcqContainerView.addSubview(mcqScrollView)
        
        // Add subviews
        view.addSubview(uploadButton)
        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)
        view.addSubview(mcqContainerView)
        
        // Setup constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        mcqContainerView.translatesAutoresizingMaskIntoConstraints = false
        mcqScrollView.translatesAutoresizingMaskIntoConstraints = false
        mcqStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Upload Button
            uploadButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            uploadButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Status Label
            statusLabel.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            
            // MCQ Container
            mcqContainerView.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            mcqContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mcqContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mcqContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // MCQ ScrollView
            mcqScrollView.topAnchor.constraint(equalTo: mcqContainerView.topAnchor, constant: 10),
            mcqScrollView.leadingAnchor.constraint(equalTo: mcqContainerView.leadingAnchor, constant: 10),
            mcqScrollView.trailingAnchor.constraint(equalTo: mcqContainerView.trailingAnchor, constant: -10),
            mcqScrollView.bottomAnchor.constraint(equalTo: mcqContainerView.bottomAnchor, constant: -10),
            
            // MCQ StackView
            mcqStackView.topAnchor.constraint(equalTo: mcqScrollView.topAnchor),
            mcqStackView.leadingAnchor.constraint(equalTo: mcqScrollView.leadingAnchor),
            mcqStackView.trailingAnchor.constraint(equalTo: mcqScrollView.trailingAnchor),
            mcqStackView.bottomAnchor.constraint(equalTo: mcqScrollView.bottomAnchor),
            mcqStackView.widthAnchor.constraint(equalTo: mcqScrollView.widthAnchor)
        ])
    }
    
    @objc private func uploadButtonTapped() {
        // Create document picker
        documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .import)
        documentPicker?.delegate = self
        documentPicker?.allowsMultipleSelection = false
        
        if let documentPicker = documentPicker {
            present(documentPicker, animated: true)
        }
    }
    
    private func extractTextFromPDF(url: URL) {
        guard let pdfDocument = PDFDocument(url: url) else {
            statusLabel.text = "Could not load PDF document"
            return
        }
        
        var extractedText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                if let pageText = page.string {
                    extractedText += pageText + "\n"
                }
            }
        }
        
        pdfContent = extractedText
        statusLabel.text = "PDF uploaded successfully. Generating MCQs..."
        generateMCQs(from: extractedText)
    }
    
    private func generateMCQs(from content: String) {
        activityIndicator.startAnimating()
        
        geminiClient.generateMCQs(from: content) { [weak self] result in
            guard let self = self else { return }
            
            self.activityIndicator.stopAnimating()
            
            switch result {
            case .success(let mcqs):
                self.displayMCQs(mcqs)
                self.statusLabel.text = "MCQs generated successfully!"
                self.mcqContainerView.isHidden = false
                
            case .failure(let error):
                self.statusLabel.text = "Error generating MCQs: \(error.localizedDescription)"
            }
        }
    }
    
    private func displayMCQs(_ mcqs: [MCQuestion]) {
        // Clear existing MCQs
        mcqStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Create and add new MCQ views
        for (index, mcq) in mcqs.enumerated() {
            let mcqView = createMCQView(mcq: mcq, index: index)
            mcqStackView.addArrangedSubview(mcqView)
        }
    }
    
    private func createMCQView(mcq: MCQuestion, index: Int) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8
        
        // Question Label
        let questionLabel = UILabel()
        questionLabel.text = "Q\(index + 1): \(mcq.question)"
        questionLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        questionLabel.numberOfLines = 0
        
        // Options Stack
        let optionsStack = UIStackView()
        optionsStack.axis = .vertical
        optionsStack.spacing = 8
        optionsStack.alignment = .leading
        
        for (optionIndex, option) in mcq.options.enumerated() {
            let optionButton = UIButton(type: .system)
            optionButton.setTitle("\(Character(UnicodeScalar(65 + optionIndex)!)). \(option)", for: .normal)
            optionButton.contentHorizontalAlignment = .left
            optionButton.titleLabel?.numberOfLines = 0
            optionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            optionButton.tag = optionIndex
            optionButton.addTarget(self, action: #selector(optionSelected(_:)), for: .touchUpInside)
            
            // Make button full width
            optionButton.translatesAutoresizingMaskIntoConstraints = false
            optionsStack.addArrangedSubview(optionButton)
            
            NSLayoutConstraint.activate([
                optionButton.widthAnchor.constraint(equalTo: optionsStack.widthAnchor)
            ])
        }
        
        // Store correct answer index in container view's tag
        containerView.tag = mcq.correctAnswerIndex
        
        // Add to container
        containerView.addSubview(questionLabel)
        containerView.addSubview(optionsStack)
        
        // Configure constraints
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            questionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            questionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            optionsStack.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 12),
            optionsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            optionsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            optionsStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        return containerView
    }
    
    @objc private func optionSelected(_ sender: UIButton) {
        // Handle option selection
        guard let optionsStack = sender.superview as? UIStackView,
              let containerView = optionsStack.superview else {
            return
        }
        
        let questionIndex = mcqStackView.arrangedSubviews.firstIndex(of: containerView) ?? 0
        let optionIndex = sender.tag
        let correctAnswerIndex = containerView.tag
        
        print("Selected option \(optionIndex) for question \(questionIndex)")
        
        // Highlight the selected option
        for case let optionButton as UIButton in optionsStack.arrangedSubviews {
            if optionButton == sender {
                // Highlight selected option
                if optionIndex == correctAnswerIndex {
                    // Correct answer
                    optionButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
                    optionButton.setTitleColor(.systemGreen, for: .normal)
                } else {
                    // Wrong answer
                    optionButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
                    optionButton.setTitleColor(.systemRed, for: .normal)
                    
                    // Also highlight the correct answer
                    if let correctButton = optionsStack.arrangedSubviews[correctAnswerIndex] as? UIButton {
                        correctButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
                        correctButton.setTitleColor(.systemGreen, for: .normal)
                    }
                }
            } else if optionButton.tag != correctAnswerIndex {
                // Reset other options
                optionButton.backgroundColor = .clear
                optionButton.setTitleColor(.systemBlue, for: .normal)
            }
        }
    }
}

// MARK: - Document Picker Delegate
extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // Start accessing the security-scoped resource
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Extract text from PDF
        extractTextFromPDF(url: url)
    }
}
