import UIKit
import FirebaseAuth

class HomeViewController: UIViewController {

    @IBOutlet weak var unsettledTableView: UITableView!
    @IBOutlet weak var waitingOnTableView: UITableView!

    var unsettledExpenses: [Expense] = []
    var waitingOnExpenses: [Expense] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        unsettledTableView.dataSource = self
        waitingOnTableView.dataSource = self
        unsettledTableView.delegate = self
        waitingOnTableView.delegate = self

        fetchExpenses()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchExpenses()
    }

    func fetchExpenses() {
        ExpenseService.shared.fetchExpensesForCurrentUser { result in
            switch result {
            case .success(let expenses):
                self.categorize(expenses)
            case .failure(let error):
                print("❌ Error fetching expenses: \(error)")
            }
        }
    }

    func categorize(_ expenses: [Expense]) {
        guard let email = Auth.auth().currentUser?.email else { return }

        unsettledExpenses = expenses.filter {
            $0.status == "open" && $0.paidBy != email && $0.members.contains(email)
        }

        waitingOnExpenses = expenses.filter {
            $0.status == "open" && $0.paidBy == email && $0.members.count > 1
        }

        unsettledTableView.reloadData()
        waitingOnTableView.reloadData()
    }

    private func presentExpenseActions(for expense: Expense) {
        let actionSheet = UIAlertController(
            title: expense.title,
            message: "Paid by \(expense.paidBy)",
            preferredStyle: .actionSheet
        )

        if !expense.isSettled {
            actionSheet.addAction(UIAlertAction(title: "Mark as Settled", style: .default) { _ in
                self.confirmMarkSettled(expense)
            })
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = view.bounds
        }

        present(actionSheet, animated: true)
    }

    private func confirmMarkSettled(_ expense: Expense) {
        guard let groupId = expense.groupId else {
            print("❌ No groupId on expense")
            return
        }

        let alert = UIAlertController(
            title: "Mark as Settled?",
            message: "This expense will move into settled history.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Mark Settled", style: .default) { _ in
            ExpenseService.shared.markExpenseSettled(groupId: groupId, expenseId: expense.id) { error in
                DispatchQueue.main.async {
                    if let error {
                        print("❌ Error settling: \(error)")
                        return
                    }
                    self.fetchExpenses()
                }
            }
        })

        present(alert, animated: true)
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return tableView == unsettledTableView
            ? unsettledExpenses.count
            : waitingOnExpenses.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .value1, reuseIdentifier: "expenseCell")

        let expense = tableView == unsettledTableView
            ? unsettledExpenses[indexPath.row]
            : waitingOnExpenses[indexPath.row]

        guard let email = Auth.auth().currentUser?.email else { return cell }

        cell.textLabel?.text = expense.title

        if expense.paidBy == email {
            let othersOwe = expense.amountCents - expense.splitAmount
            cell.detailTextLabel?.text = String(format: "+$%.2f", Double(othersOwe) / 100)
            cell.detailTextLabel?.textColor = .systemGreen
        } else {
            cell.detailTextLabel?.text = String(format: "-$%.2f", Double(expense.splitAmount) / 100)
            cell.detailTextLabel?.textColor = .systemRed
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let expense = tableView == unsettledTableView
            ? unsettledExpenses[indexPath.row]
            : waitingOnExpenses[indexPath.row]

        presentExpenseActions(for: expense)
    }
}
