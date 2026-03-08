import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var unsettledTableView: UITableView!
    @IBOutlet weak var waitingOnTableView: UITableView!

    // Mock data using the existing Expense struct
    var unsettledExpenses: [Expense] = [
        Expense(id: "1", title: "Lunch with Friends", amountCents: 2500, paidBy: "Alice"),
        Expense(id: "2", title: "Groceries", amountCents: 5200, paidBy: "Olivia")
    ]

    var waitingOnExpenses: [Expense] = [
        Expense(id: "3", title: "Movie Tickets", amountCents: 1800, paidBy: "Bob"),
        Expense(id: "4", title: "Coffee", amountCents: 700, paidBy: "Charlie")
    ]
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Home"

        unsettledTableView.dataSource = self
        unsettledTableView.delegate = self

        waitingOnTableView.dataSource = self
        waitingOnTableView.delegate = self

        unsettledTableView.register(UITableViewCell.self, forCellReuseIdentifier: "expenseCell")
        waitingOnTableView.register(UITableViewCell.self, forCellReuseIdentifier: "expenseCell")
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if tableView == unsettledTableView {
            return unsettledExpenses.count
        } else {
            return waitingOnExpenses.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "expenseCell", for: indexPath)
        let expense = (tableView == unsettledTableView) ? unsettledExpenses[indexPath.row] : waitingOnExpenses[indexPath.row]

        cell.textLabel?.text = expense.title

        let amountLabel = UILabel()
        amountLabel.text = "$\(Double(expense.amountCents)/100)"
        amountLabel.sizeToFit()
        cell.accessoryView = amountLabel

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
