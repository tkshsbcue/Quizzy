import UIKit
import PDFKit

class LegacyViewController: UIViewController {
    
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
    private let geminiClient = GeminiAPIClient(apiKey: "AIzaSyDRl0jeTUOY6lmT_PUbd_aMquGIfQujhxQ")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .quizzyBackground
        title = "PDF to MCQ Generator"
        
        // Upload Button
        uploadButton.setTitle("Upload PDF", for: .normal)
        uploadButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        uploadButton.backgroundColor = .quizzyPrimary
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.layer.cornerRadius = 16
        uploadButton.layer.shadowColor = UIColor.black.cgColor
        uploadButton.layer.shadowOpacity = 0.15
        uploadButton.layer.shadowRadius = 8
        uploadButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        
        // Status Label
        statusLabel.text = "Upload a PDF to generate MCQs"
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .quizzyTextMedium
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .quizzyPrimary
        
        // MCQ Container
        mcqContainerView.backgroundColor = .white
        mcqContainerView.layer.borderColor = UIColor.quizzyTextLight.cgColor
        mcqContainerView.layer.borderWidth = 1
        mcqContainerView.layer.cornerRadius = 16
        mcqContainerView.layer.shadowColor = UIColor.black.cgColor
        mcqContainerView.layer.shadowOpacity = 0.1
        mcqContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        mcqContainerView.layer.shadowRadius = 8
        mcqContainerView.isHidden = true
        
        // MCQ ScrollView and StackView
        mcqStackView.axis = .vertical
        mcqStackView.spacing = 20
        mcqStackView.alignment = .fill
        mcqStackView.distribution = .fill
        mcqScrollView.showsVerticalScrollIndicator = false
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
        // Reset UI before starting
        mcqContainerView.isHidden = true
        mcqStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        activityIndicator.startAnimating()
        statusLabel.text = "Reading PDF content..."
        
        // First try to load PDF document directly
        guard let pdfDocument = PDFDocument(url: url) else {
            statusLabel.text = "Could not load PDF document"
            activityIndicator.stopAnimating()
            return
        }
        
        // For smaller PDFs, we'll extract text more carefully
        var extractedText = ""
        let pageCount = pdfDocument.pageCount
        
        // Log PDF info
        print("PDF loaded successfully. Page count: \(pageCount)")
        
        // Extract text from each page
        for i in 0..<pageCount {
            if let page = pdfDocument.page(at: i) {
                if let pageText = page.string {
                    extractedText += pageText + "\n"
                    print("Extracted \(pageText.count) characters from page \(i+1)")
                } else {
                    print("No text content in page \(i+1)")
                }
            }
        }
        
        // Check if we got any text
        if extractedText.isEmpty {
            print("No text extracted from PDF. Attempting fallback method...")
            
            // Try to read the PDF data and process it differently
            do {
                let pdfData = try Data(contentsOf: url)
                if let fallbackDocument = PDFDocument(data: pdfData) {
                    for i in 0..<fallbackDocument.pageCount {
                        if let page = fallbackDocument.page(at: i) {
                            if let pageText = page.string {
                                extractedText += pageText + "\n"
                            }
                        }
                    }
                }
            } catch {
                print("Fallback method failed: \(error.localizedDescription)")
            }
        }
        
        // Check again if we got any text
        if extractedText.isEmpty {
            statusLabel.text = "Could not extract text from this PDF"
            activityIndicator.stopAnimating()
            
            let alert = UIAlertController(
                title: "PDF Text Extraction Failed",
                message: "This PDF doesn't contain extractable text. It may be a scanned document or image-based PDF. Please try a different PDF.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // For a 250-word PDF, the text should be quite manageable
        print("Total extracted text: \(extractedText.count) characters")
        
        // Store the extracted content and generate MCQs
        pdfContent = extractedText
        statusLabel.text = "PDF content extracted. Generating MCQs..."
        generateMCQs(from: extractedText)
    }
    
    private func generateMCQs(from content: String) {
        // Validate content before sending to API
        guard !content.isEmpty else {
            statusLabel.text = "Error: No content to generate MCQs from"
            activityIndicator.stopAnimating()
            return
        }
        
        print("Generating MCQs from \(content.count) characters")
        activityIndicator.startAnimating()
        statusLabel.text = "Generating MCQs from PDF. Please wait..."
        
        // Add a brief delay to ensure UI updates are visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            self.geminiClient.generateMCQs(from: content) { [weak self] result in
                guard let self = self else { return }
                
                self.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let mcqs):
                    // Check if we got any MCQs
                    if mcqs.isEmpty {
                        self.statusLabel.text = "No valid MCQs could be generated from this content"
                        return
                    }
                    
                    self.displayMCQs(mcqs)
                    self.statusLabel.text = "MCQs generated successfully!"
                    self.mcqContainerView.isHidden = false
                    
                case .failure(let error):
                    let errorMessage = "Error generating MCQs: \(error.localizedDescription)"
                    self.statusLabel.text = errorMessage
                    print("Failed with error: \(error)")
                    
                    // If it's a network error, show a retry dialog
                    if (error as NSError).domain == NSURLErrorDomain || 
                       error is GeminiAPIClient.APIError {
                        
                        // Show retry alert with options
                        let alert = UIAlertController(
                            title: "Connection Problem",
                            message: "There was an issue connecting to the Gemini API. What would you like to do?",
                            preferredStyle: .alert
                        )
                        
                        // Option 1: Try with shorter content
                        if content.count > 1000 {
                            alert.addAction(UIAlertAction(title: "Try Shorter Content", style: .default) { [weak self] _ in
                                guard let self = self else { return }
                                
                                // For a ~250 word PDF, 1000 chars should be enough
                                let shorterContent = String(content.prefix(1000))
                                self.statusLabel.text = "Retrying with shorter content..."
                                self.generateMCQs(from: shorterContent)
                            })
                        }
                        
                        // Option 2: Try again
                        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
                            guard let self = self else { return }
                            self.statusLabel.text = "Retrying..."
                            self.generateMCQs(from: content)
                        })
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }
    
    private func displayMCQs(_ mcqs: [MCQuestion]) {
        // Clear existing MCQs
        mcqStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Create and add new MCQ views
        for (index, mcq) in mcqs.enumerated() {
            let mcqView = createMCQView(for: mcq)
            mcqStackView.addArrangedSubview(mcqView)
        }
    }
    
    private func createMCQView(for mcq: MCQuestion) -> UIView {
        // Create our custom MCQuestionView
        let mcqView = MCQuestionView(frame: .zero)
        
        // Configure the MCQuestionView
        mcqView.configure(with: mcq.question, options: mcq.options, correctAnswerIndex: mcq.correctAnswerIndex)
        
        return mcqView
    }
}

// MARK: - Document Picker Delegate
extension LegacyViewController: UIDocumentPickerDelegate {
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
