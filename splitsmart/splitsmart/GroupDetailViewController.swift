import UIKit
import FirebaseFirestore

class GroupDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var membersStackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tripNameLabel: UILabel!
    @IBOutlet weak var eventIdLabel: UILabel!

    var group: Group?
    var expenses: [Expense] = []

    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()

        tripNameLabel.text = group?.name

        tableView.dataSource = self
        tableView.delegate = self

        fetchGroupInfo()
        fetchMembers()
        fetchExpenses()
    }
    
    func fetchGroupInfo() {

        guard let groupId = group?.id else { return }

        db.collection("groups")
            .document(groupId)
            .getDocument { snapshot, error in

            if let data = snapshot?.data() {

                let joinCode = data["joinCode"] as? String ?? ""

                DispatchQueue.main.async {
                    self.eventIdLabel.text = "Event ID: \(joinCode)"
                }
            }
        }
    }

    func fetchMembers() {

        guard let groupId = group?.id else { return }

        db.collection("groups")
            .document(groupId)
            .getDocument { snapshot, error in

            if let data = snapshot?.data() {

                let members = data["members"] as? [String] ?? []

                DispatchQueue.main.async {
                    self.displayMembers(members)
                }
            }
        }
    }

    func displayMembers(_ members: [String]) {

        // Clear existing views
        membersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for member in members {

            let label = PaddingLabel()
            label.text = "👤 \(member)"
            label.backgroundColor = UIColor.systemGray5
            label.layer.cornerRadius = 10
            label.clipsToBounds = true
            label.font = UIFont.systemFont(ofSize: 14)

            membersStackView.addArrangedSubview(label)
        }
    }
    func fetchExpenses() {

        guard let groupId = group?.id else { return }

        db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .getDocuments { snapshot, error in

                if let error = error {
                    print(error)
                    return
                }

                self.expenses.removeAll()

                snapshot?.documents.forEach { doc in
                    let data = doc.data()

                    let expense = Expense(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        amountCents: data["amountCents"] as? Int ?? 0,
                        paidBy: data["paidBy"] as? String ?? ""
                    )

                    self.expenses.append(expense)
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
}

extension GroupDetailViewController {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expenses.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "expenseCell", for: indexPath)

        let expense = expenses[indexPath.row]

        if let titleLabel = cell.viewWithTag(1) as? UILabel {
            titleLabel.text = expense.title
        }

        if let amountLabel = cell.viewWithTag(2) as? UILabel {
            amountLabel.text = "$\(Double(expense.amountCents) / 100)"
        }

        if let paidByLabel = cell.viewWithTag(3) as? UILabel {
            paidByLabel.text = "Paid by: \(expense.paidBy)"
        }

        return cell
    }
}
