import UIKit

class QuizCell: UITableViewCell {
    static let identifier = "QuizCell"
    
    // UI Components
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let iconView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Container view with shadow and rounded corners
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        
        // Icon view
        iconView.image = UIImage(systemName: "doc.text.fill")
        iconView.tintColor = .quizzyPrimary
        iconView.contentMode = .scaleAspectFit
        
        // Title label
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .quizzyTextDark
        titleLabel.numberOfLines = 1
        
        // Add subviews
        contentView.addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        
        // Setup constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Icon view
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            
            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}

class QuizzesViewController: UIViewController {
    
    // UI Components
    private let tableView = UITableView()
    private let emptyStateView = UIView()
    private let emptyStateImageView = UIImageView()
    private let emptyStateLabel = UILabel()
    private let createQuizButton = UIButton(type: .system)
    
    // Sample data - in a real app this would come from persistent storage
    private let sampleQuizzes = [
        "Science Quiz",
        "History Quiz",
        "Literature Quiz",
        "Mathematics Quiz",
        "Geography Quiz"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .quizzyBackground
        title = "My Quizzes"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Setup table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(QuizCell.self, forCellReuseIdentifier: QuizCell.identifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        // Empty state image
        emptyStateImageView.image = UIImage(systemName: "doc.text.magnifyingglass")
        emptyStateImageView.tintColor = .quizzyTextMedium
        emptyStateImageView.contentMode = .scaleAspectFit
        
        // Empty state label
        emptyStateLabel.text = "You haven't saved any quizzes yet"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyStateLabel.textColor = .quizzyTextMedium
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        
        // Create quiz button in empty state
        var config = UIButton.Configuration.filled()
        config.title = "Create a Quiz"
        config.image = UIImage(systemName: "plus")
        config.imagePadding = 8
        config.baseBackgroundColor = .quizzyPrimary
        config.cornerStyle = .large
        createQuizButton.configuration = config
        createQuizButton.addTarget(self, action: #selector(createQuizButtonTapped), for: .touchUpInside)
        
        // Add components to empty state view
        emptyStateView.addSubview(emptyStateImageView)
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.addSubview(createQuizButton)
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        
        // Toggle visibility based on data
        emptyStateView.isHidden = !sampleQuizzes.isEmpty
        tableView.isHidden = sampleQuizzes.isEmpty
        
        // Setup constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        createQuizButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Empty state view
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Empty state image
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Empty state label
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 16),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            
            // Create quiz button
            createQuizButton.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 24),
            createQuizButton.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            createQuizButton.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor),
            createQuizButton.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor),
            createQuizButton.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    @objc private func createQuizButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension QuizzesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sampleQuizzes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: QuizCell.identifier, for: indexPath) as? QuizCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: sampleQuizzes[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // In a real app, this would load the quiz from persistent storage
        let alert = UIAlertController(
            title: "Open Quiz",
            message: "This would open the '\(sampleQuizzes[indexPath.row])' quiz",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
} 