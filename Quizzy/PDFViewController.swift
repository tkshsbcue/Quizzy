import UIKit
import PDFKit

class PDFViewController: UIViewController {
    
    // UI Components
    private let uploadButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // PDF Content
    private var pdfContent: String?
    private var documentPicker: UIDocumentPickerViewController?
    
    // Generated MCQs
    private var generatedMCQs: [MCQuestion] = []
    
    // Gemini API Client
    private let geminiClient = GeminiAPIClient(apiKey: "AIzaSyDRl0jeTUOY6lmT_PUbd_aMquGIfQujhxQ")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Generate MCQs"
        
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
        
        // Add subviews
        view.addSubview(uploadButton)
        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)
        
        // Setup constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Upload Button
            uploadButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
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
                    
                    self.statusLabel.text = "MCQs generated successfully!"
                    
                    // Use the storyboard segue and pass data through prepare(for:sender:)
                    self.generatedMCQs = mcqs
                    self.performSegue(withIdentifier: "ShowResults", sender: self)
                    
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
                            message: "There was an issue connecting to the AI service. Would you like to retry?",
                            preferredStyle: .alert
                        )
                        
                        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
                            if let content = self?.pdfContent {
                                self?.generateMCQs(from: content)
                            }
                        })
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension PDFViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            print("No PDF selected")
            return
        }
        
        print("Selected PDF: \(url.lastPathComponent)")
        
        // Start security-scoped resource access
        let securityScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if securityScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Extract text from the selected PDF
        extractTextFromPDF(url: url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
}

// MARK: - Navigation
extension PDFViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowResults" {
            if let resultsVC = segue.destination as? ResultsViewController {
                resultsVC.mcqs = self.generatedMCQs
            }
        }
    }
} 