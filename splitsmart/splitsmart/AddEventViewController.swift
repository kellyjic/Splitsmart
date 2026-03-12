import UIKit

class AddEventViewController: UIViewController {

    var onGroupCreated: (() -> Void)?

    @IBOutlet weak var eventNameTextField: UITextField!
    @IBOutlet weak var infoLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        infoLabel.text = "To add members, share the Event ID that appears after clicking 'Create'."
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.textColor = .systemGray
        infoLabel.backgroundColor = UIColor.systemGray6
        infoLabel.layer.cornerRadius = 14
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    

    @IBAction func createEventTapped(_ sender: UIButton) {
        guard let name = eventNameTextField.text, !name.isEmpty else {
            print("Event name required")
            return
        }

        GroupService.shared.createGroup(name: name) { joinCode, error in
            if let error = error {
                print("Error creating group:", error)
                return
            }

            guard let code = joinCode else { return }

            DispatchQueue.main.async {

                let alert = UIAlertController(
                    title: "Event Created",
                    message: "Share this Event ID with others to join:\n\n\(code)",
                    preferredStyle: .alert
                )

                let okAction = UIAlertAction(title: "OK", style: .default) { _ in

                    self.onGroupCreated?()

                    if let nav = self.navigationController {
                        nav.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true)
                    }
                }

                alert.addAction(okAction)

                self.present(alert, animated: true)
            }
        }
    }
}
