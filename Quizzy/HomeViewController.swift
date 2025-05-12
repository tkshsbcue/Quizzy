import UIKit

class HomeViewController: UIViewController {
    
    // UI Components
    private let logoImageView = UIImageView()
    private let logoLabel = UILabel()
    private let generateButton = UIButton(type: .system)
    private let quizzesButton = UIButton(type: .system)
    private let containerView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Navigation bar appearance
        title = "Quizzy"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .quizzyPrimary
        navigationItem.largeTitleDisplayMode = .always
        
        // Background gradient
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.quizzyBackground.cgColor,
            UIColor.white.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Container for buttons
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 24
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 10
        
        // Logo image or app icon placeholder (you can replace with actual logo)
        logoImageView.image = UIImage(systemName: "questionmark.app.fill")
        logoImageView.tintColor = .quizzyPrimary
        logoImageView.contentMode = .scaleAspectFit
        
        // App name label
        logoLabel.text = "Quizzy"
        logoLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        logoLabel.textColor = .quizzyPrimary
        logoLabel.textAlignment = .center
        
        // Generate MCQs button
        configureButton(generateButton, 
                       title: "Generate Quiz from PDF", 
                       icon: "doc.text.viewfinder", 
                       backgroundColor: .quizzyPrimary)
        generateButton.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
        
        // My Quizzes button
        configureButton(quizzesButton, 
                       title: "My Quizzes", 
                       icon: "list.bullet.clipboard", 
                       backgroundColor: .quizzySecondary)
        quizzesButton.addTarget(self, action: #selector(quizzesButtonTapped), for: .touchUpInside)
        
        // Add subviews
        view.addSubview(logoImageView)
        view.addSubview(logoLabel)
        view.addSubview(containerView)
        containerView.addSubview(generateButton)
        containerView.addSubview(quizzesButton)
        
        setupConstraints()
    }
    
    private func configureButton(_ button: UIButton, title: String, icon: String, backgroundColor: UIColor) {
        // Create button configuration
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        config.cornerStyle = .large
        config.baseBackgroundColor = backgroundColor
        
        // Apply configuration
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Logo image
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 100),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            
            // Logo label
            logoLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 8),
            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Container view
            containerView.topAnchor.constraint(greaterThanOrEqualTo: logoLabel.bottomAnchor, constant: 40),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            
            // Generate button
            generateButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            generateButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            generateButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Quizzes button
            quizzesButton.topAnchor.constraint(equalTo: generateButton.bottomAnchor, constant: 16),
            quizzesButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            quizzesButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            quizzesButton.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -30)
        ])
    }
    
    @objc private func generateButtonTapped() {
        performSegue(withIdentifier: "ShowPDFViewController", sender: nil)
    }
    
    @objc private func quizzesButtonTapped() {
        performSegue(withIdentifier: "ShowQuizzesViewController", sender: nil)
    }
} 