import UIKit
import FirebaseAuth
import FirebaseFirestore

final class ProfileViewController: UIViewController {

    private let db = Firestore.firestore()

    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let groupsTitleLabel = UILabel()
    private let groupsLabel = UILabel()
    private let logoutButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Profile"
        view.backgroundColor = .systemBackground

        configureViews()
        layoutViews()
        populateUserInfo()
        loadGroups()
    }

    private func configureViews() {
        nameLabel.font = .boldSystemFont(ofSize: 28)
        emailLabel.font = .systemFont(ofSize: 16)
        emailLabel.textColor = .secondaryLabel

        groupsTitleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        groupsTitleLabel.text = "Your Groups"

        groupsLabel.font = .systemFont(ofSize: 16)
        groupsLabel.textColor = .secondaryLabel
        groupsLabel.numberOfLines = 0
        groupsLabel.text = "Loading..."

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Log Out"
        configuration.cornerStyle = .large
        configuration.baseBackgroundColor = .systemRed
        logoutButton.configuration = configuration
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    }

    private func layoutViews() {
        let stackView = UIStackView(arrangedSubviews: [
            nameLabel,
            emailLabel,
            groupsTitleLabel,
            groupsLabel,
            logoutButton
        ])

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func populateUserInfo() {
        let email = Auth.auth().currentUser?.email ?? "No email found"
        let displayName = Auth.auth().currentUser?.displayName
        let fallbackName = email.components(separatedBy: "@").first?.capitalized ?? "User"

        nameLabel.text = displayName?.isEmpty == false ? displayName : fallbackName
        emailLabel.text = email
    }

    private func loadGroups() {
        guard let email = Auth.auth().currentUser?.email else {
            groupsLabel.text = "No groups found."
            return
        }

        db.collection("groups")
            .whereField("members", arrayContains: email)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error {
                        self.groupsLabel.text = error.localizedDescription
                        return
                    }

                    let groups = snapshot?.documents.compactMap { $0.data()["name"] as? String } ?? []
                    self.groupsLabel.text = groups.isEmpty ? "No groups yet." : groups.joined(separator: "\n")
                }
            }
    }

    @objc
    private func logoutTapped() {
        do {
            try AuthManager.shared.signOut()
        } catch {
            let alert = UIAlertController(title: "Unable to log out", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginViewController = storyboard.instantiateInitialViewController() else { return }

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = loginViewController
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: nil)
        }
    }
}
