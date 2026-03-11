import UIKit
import FirebaseFirestore

class GroupDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var membersStackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tripNameLabel: UILabel!
    @IBOutlet weak var eventIdLabel: UILabel!
    
    @IBAction func addExpenseTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToAddExpense", sender: nil)
    }

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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

        ExpenseService.shared.fetchExpenses(groupId: groupId, groupName: group?.name) { result in
            switch result {
            case .success(let expenses):
                DispatchQueue.main.async {
                    self.expenses = expenses
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToAddExpense",
           let destination = segue.destination as? AddExpensesViewController {
            destination.group = group
            destination.members = group?.members ?? []
            destination.onExpenseSaved = { 
                self.fetchExpenses()
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
            titleLabel.text = expense.isSettled ? "\(expense.title) • Settled" : expense.title
        }

        if let amountLabel = cell.viewWithTag(2) as? UILabel {
            amountLabel.text = String(format: "$%.2f", Double(expense.splitAmount) / 100)
            amountLabel.textColor = expense.isSettled ? .systemGreen : .systemRed
        }

        cell.accessoryType = .detailButton

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentExpenseActions(for: expenses[indexPath.row])
    }

    private func presentExpenseActions(for expense: Expense) {
        let actionSheet = UIAlertController(title: expense.title, message: "Paid by \(expense.paidBy)", preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Edit Expense", style: .default) { _ in
            self.presentEditExpenseAlert(for: expense)
        })

        if !expense.isSettled {
            actionSheet.addAction(UIAlertAction(title: "Mark as Settled", style: .default) { _ in
                self.confirmMarkSettled(expense)
            })
        }

        actionSheet.addAction(UIAlertAction(title: "Delete Expense", style: .destructive) { _ in
            self.confirmDelete(expense)
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.bounds
        }

        present(actionSheet, animated: true)
    }

    private func presentEditExpenseAlert(for expense: Expense) {
        let alert = UIAlertController(title: "Edit Expense", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Expense name"
            textField.text = expense.title
        }

        alert.addTextField { textField in
            textField.placeholder = "Amount"
            textField.keyboardType = .decimalPad
            textField.text = String(format: "%.2f", Double(expense.amountCents) / 100)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            guard
                let groupId = self.group?.id,
                let title = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                !title.isEmpty,
                let amountText = alert.textFields?.last?.text,
                let amount = Double(amountText)
            else {
                return
            }

            ExpenseService.shared.updateExpense(
                groupId: groupId,
                expenseId: expense.id,
                title: title,
                amountCents: Int(amount * 100),
                splitCount: expense.members.count
            ) { error in
                DispatchQueue.main.async {
                    if let error {
                        self.presentErrorAlert(message: error.localizedDescription)
                        return
                    }

                    self.fetchExpenses()
                }
            }
        })

        present(alert, animated: true)
    }

    private func confirmDelete(_ expense: Expense) {
        let alert = UIAlertController(
            title: "Delete Expense?",
            message: "This action cannot be undone.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            guard let groupId = self.group?.id else { return }

            ExpenseService.shared.deleteExpense(groupId: groupId, expenseId: expense.id) { error in
                DispatchQueue.main.async {
                    if let error {
                        self.presentErrorAlert(message: error.localizedDescription)
                        return
                    }

                    self.fetchExpenses()
                }
            }
        })

        present(alert, animated: true)
    }

    private func confirmMarkSettled(_ expense: Expense) {
        let alert = UIAlertController(
            title: "Mark as Settled?",
            message: "This expense will move into settled history.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Mark Settled", style: .default) { _ in
            guard let groupId = self.group?.id else { return }

            ExpenseService.shared.markExpenseSettled(groupId: groupId, expenseId: expense.id) { error in
                DispatchQueue.main.async {
                    if let error {
                        self.presentErrorAlert(message: error.localizedDescription)
                        return
                    }

                    self.fetchExpenses()
                }
            }
        })

        present(alert, animated: true)
    }

    private func presentErrorAlert(message: String) {
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
