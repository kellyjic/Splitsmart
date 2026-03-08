import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.isSecureTextEntry = true

    }

    @IBAction func createAccountTapped(_ sender: UIButton) {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty,
              !password.isEmpty else {
            print("Email or password is empty")
            return
        }

        AuthManager.shared.createUser(email: email, password: password) { result in
            switch result {
            case .success(let user):
                UserService.shared.createUserDocument(uid: user.uid, email: email) { error in
                    if let error = error {
                        print("Firestore error: \(error.localizedDescription)")
                        return
                    }

                    print("User created and Firestore doc added")
                }

            case .failure(let error):
                print("Signup error: \(error.localizedDescription)")
            }
        }
    }

    @IBAction func loginTapped(_ sender: UIButton) {
    guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty,
              !password.isEmpty else {
            print("Email or password is empty")
            return
        }

        AuthManager.shared.login(email: email, password: password) { result in
            switch result {
            case .success(_):
                print("User logged in")
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as! UITabBarController
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let sceneDelegate = windowScene.delegate as? SceneDelegate,
                   let window = sceneDelegate.window {
                    window.rootViewController = tabBarController
                    UIView.transition(with: window,
                                      duration: 0.3,
                                      options: .transitionFlipFromRight,
                                      animations: nil)
                }
                
            case .failure(let error):
                print("Login error: \(error.localizedDescription)")
            }
        }
    }
}
