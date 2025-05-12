import UIKit
import PDFKit
import UniformTypeIdentifiers

class PDFViewController: UIViewController, UIDocumentPickerDelegate {
    
    // UI Components
    private let uploadButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let pdfView = PDFView()
    private let generateButton = UIButton(type: .system)
    private let useSampleButton = UIButton(type: .system)
    
    // PDF Content
    private var pdfContent: String?
    
    // Generated MCQs
    private var generatedMCQs: [MCQuestion] = []
    
    // Gemini API Client
    private let geminiClient = GeminiAPIClient(apiKey: "AIzaSyDRl0jeTUOY6lmT_PUbd_aMquGIfQujhxQ")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .quizzyBackground
        title = "Generate Quiz"
        
        // Configure the upload button
        uploadButton.setTitle("Upload PDF", for: .normal)
        uploadButton.backgroundColor = .quizzyPrimary
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.layer.cornerRadius = 16
        uploadButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        uploadButton.layer.shadowColor = UIColor.black.cgColor
        uploadButton.layer.shadowOpacity = 0.15
        uploadButton.layer.shadowRadius = 8
        uploadButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        
        // Configure use sample button
        useSampleButton.setTitle("Use Sample PDF", for: .normal)
        useSampleButton.backgroundColor = .quizzySecondary
        useSampleButton.setTitleColor(.white, for: .normal)
        useSampleButton.layer.cornerRadius = 16
        useSampleButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        useSampleButton.layer.shadowColor = UIColor.black.cgColor
        useSampleButton.layer.shadowOpacity = 0.15
        useSampleButton.layer.shadowRadius = 8
        useSampleButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        useSampleButton.addTarget(self, action: #selector(useSampleButtonTapped), for: .touchUpInside)
        
        // Configure status label
        statusLabel.text = "Upload a PDF to generate a quiz"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .quizzyTextMedium
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // Configure activity indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .quizzyPrimary
        
        // Configure PDF view
        pdfView.backgroundColor = .white
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.layer.cornerRadius = 16
        pdfView.layer.borderWidth = 1
        pdfView.layer.borderColor = UIColor.quizzyTextLight.cgColor
        pdfView.isHidden = true
        
        // Configure generate button
        generateButton.setTitle("Generate Quiz", for: .normal)
        generateButton.backgroundColor = .quizzyPrimary
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.layer.cornerRadius = 16
        generateButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        generateButton.layer.shadowColor = UIColor.black.cgColor
        generateButton.layer.shadowOpacity = 0.15
        generateButton.layer.shadowRadius = 8
        generateButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        generateButton.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
        generateButton.isHidden = true
        
        // Add subviews
        view.addSubview(uploadButton)
        view.addSubview(useSampleButton)
        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)
        view.addSubview(pdfView)
        view.addSubview(generateButton)
        
        // Set up constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        useSampleButton.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Upload Button
            uploadButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            uploadButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            uploadButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Use Sample Button
            useSampleButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            useSampleButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            useSampleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            useSampleButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Status Label
            statusLabel.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            
            // PDF View
            pdfView.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pdfView.bottomAnchor.constraint(equalTo: generateButton.topAnchor, constant: -20),
            
            // Generate Button
            generateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            generateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            generateButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            generateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func uploadButtonTapped() {
        // Fixed document picker implementation
        let supportedTypes: [UTType] = [UTType.pdf]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.modalPresentationStyle = .formSheet
        
        // Present the document picker
        present(documentPicker, animated: true)
    }
    
    @objc private func useSampleButtonTapped() {
        // Generate a sample PDF for testing
        let samplePDFURL = createSamplePDF()
        extractTextFromPDF(url: samplePDFURL)
    }
    
    private func createSamplePDF() -> URL {
        // Create a PDF with some sample text content
        let pdfData = NSMutableData()
        let pdfFormatter = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sample.pdf")
        
        let pdf = pdfFormatter.pdfData { context in
            context.beginPage()
            
            // Add a title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            
            let title = "Machine Learning Fundamentals"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Add some content paragraphs
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            
            let paragraph1 = """
            Machine learning is a subset of artificial intelligence that focuses on building systems that learn from data. 
            Unlike traditional computer programs that follow explicit instructions, machine learning algorithms improve 
            automatically through experience and data.
            
            There are several types of machine learning:
            
            1. Supervised Learning: Training a model on labeled data, where the desired output is known. 
               Examples include classification and regression tasks.
            
            2. Unsupervised Learning: Finding patterns or structure in unlabeled data. 
               Examples include clustering, dimensionality reduction, and association.
            
            3. Reinforcement Learning: Training models to make decisions by rewarding desired behaviors.
               Often used in gaming, robotics, and navigation systems.
            """
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            var contentRect = CGRect(x: 50, y: 80, width: 495, height: 600)
            paragraph1.draw(in: contentRect, withAttributes: contentAttributes)
            
            // Add second page
            context.beginPage()
            
            let paragraph2 = """
            Neural networks are a cornerstone of modern machine learning, especially deep learning. 
            A neural network consists of layers of interconnected nodes or "neurons," each performing 
            simple mathematical operations. When combined and trained on large datasets, these networks 
            can model complex patterns.
            
            Key concepts in neural networks include:
            
            - Activation Functions: Functions like ReLU, sigmoid, and tanh that introduce non-linearity.
            - Backpropagation: The algorithm for calculating gradients and updating weights.
            - Gradient Descent: The optimization method used to minimize error.
            - Loss Functions: Measures like MSE and cross-entropy that quantify prediction errors.
            
            Common applications of machine learning include:
            
            1. Natural Language Processing for text analysis and generation
            2. Computer Vision for image recognition and processing
            3. Recommendation systems for suggesting products or content
            4. Predictive analytics for forecasting future trends
            5. Autonomous vehicles for self-driving capabilities
            
            The field continues to evolve rapidly with new algorithms, techniques, and applications emerging regularly.
            """
            
            contentRect = CGRect(x: 50, y: 50, width: 495, height: 700)
            paragraph2.draw(in: contentRect, withAttributes: contentAttributes)
        }
        
        // Save to file
        try? pdf.write(to: documentURL, options: [.atomicWrite])
        return documentURL
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            statusLabel.text = "No file was selected"
            return
        }
        
        // Create a local copy of the document to ensure access
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(selectedFileURL.lastPathComponent)
        
        do {
            // If file already exists, remove it first
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Copy the file to the documents directory
            try fileManager.copyItem(at: selectedFileURL, to: destinationURL)
            
            // Process the selected PDF from its new location
            extractTextFromPDF(url: destinationURL)
        } catch {
            statusLabel.text = "Error accessing file: \(error.localizedDescription)"
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        statusLabel.text = "PDF selection was cancelled"
    }
    
    private func extractTextFromPDF(url: URL) {
        // Show loading state
        activityIndicator.startAnimating()
        statusLabel.text = "Reading PDF content..."
        
        // Load the PDF document
        guard let pdfDocument = PDFDocument(url: url) else {
            statusLabel.text = "Could not load PDF document"
            activityIndicator.stopAnimating()
            return
        }
        
        // Display the PDF in the view
        pdfView.document = pdfDocument
        pdfView.isHidden = false
        
        // Extract text from each page
        var extractedText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                extractedText += pageText + "\n"
            }
        }
        
        // Check if we got any text
        if extractedText.isEmpty {
            statusLabel.text = "Could not extract text from this PDF"
            activityIndicator.stopAnimating()
            return
        }
        
        // Store the extracted text
        pdfContent = extractedText
        
        // Update UI
        generateButton.isHidden = false
        statusLabel.text = "PDF loaded. Click 'Generate Quiz' to continue."
        activityIndicator.stopAnimating()
    }
    
    @objc private func generateButtonTapped() {
        // Validate PDF content
        guard let content = pdfContent, !content.isEmpty else {
            statusLabel.text = "No PDF content to generate quiz from"
            return
        }
        
        // Generate MCQs
        generateMCQs(from: content)
    }
    
    private func generateMCQs(from content: String) {
        // Show loading state
        activityIndicator.startAnimating()
        statusLabel.text = "Generating quiz questions..."
        
        // Generate MCQs using Gemini API
        geminiClient.generateMCQs(from: content) { [weak self] result in
            guard let self = self else { return }
            
            self.activityIndicator.stopAnimating()
            
            switch result {
            case .success(let mcqs):
                if mcqs.isEmpty {
                    self.statusLabel.text = "No valid questions could be generated"
                    return
                }
                
                // Store generated MCQs and show results
                self.generatedMCQs = mcqs
                self.statusLabel.text = "Quiz generated successfully!"
                self.performSegue(withIdentifier: "ShowResults", sender: self)
                
            case .failure(let error):
                // Handle error
                self.statusLabel.text = "Error: \(error.localizedDescription)"
                
                // Show retry option
                let alert = UIAlertController(
                    title: "Generation Failed",
                    message: "Failed to generate quiz questions. Would you like to try again?",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
                    if let content = self?.pdfContent {
                        self?.generateMCQs(from: content)
                    }
                })
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                self.present(alert, animated: true)
            }
        }
    }
    
    // Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowResults", let resultsVC = segue.destination as? ResultsViewController {
            resultsVC.mcqs = self.generatedMCQs
        }
    }
} 