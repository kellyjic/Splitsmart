import UIKit

final class HistoryViewController: UIViewController {

    private let filterControl = UISegmentedControl(items: ["All", "Settled"])
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()

    private var expenses: [Expense] = []
    private var filteredExpenses: [Expense] {
        if filterControl.selectedSegmentIndex == 1 {
            return expenses.filter(\.isSettled)
        }

        return expenses
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "History"
        view.backgroundColor = .systemBackground

        configureFilter()
        configureTableView()
        configureEmptyState()
        layoutViews()
        reloadEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadExpenses()
    }

    private func configureFilter() {
        filterControl.selectedSegmentIndex = 0
        filterControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureEmptyState() {
        emptyLabel.text = "No expenses to show yet."
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func layoutViews() {
        filterControl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(filterControl)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            filterControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            filterControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            filterControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: filterControl.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    private func loadExpenses() {
        ExpenseService.shared.fetchExpensesForCurrentUser { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let expenses):
                    self.expenses = expenses
                    self.tableView.reloadData()
                    self.reloadEmptyState()
                case .failure(let error):
                    self.presentErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    private func reloadEmptyState() {
        let hasExpenses = !filteredExpenses.isEmpty
        emptyLabel.isHidden = hasExpenses
        tableView.isHidden = !hasExpenses
    }

    @objc
    private func filterChanged() {
        tableView.reloadData()
        reloadEmptyState()
    }

    private func presentErrorAlert(message: String) {
        let alert = UIAlertController(title: "Unable to load history", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredExpenses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "historyExpenseCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ??
            UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)

        let expense = filteredExpenses[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = expense.title
        content.secondaryText = "\(expense.groupName ?? "Group") • Paid by \(expense.paidBy) • \(expense.isSettled ? "Settled" : "Open")"
        cell.contentConfiguration = content

        let amountLabel = UILabel()
        amountLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        amountLabel.text = String(format: "$%.2f", Double(expense.splitAmount) / 100)
        amountLabel.textColor = expense.isSettled ? .systemGreen : .systemRed
        amountLabel.sizeToFit()
        cell.accessoryView = amountLabel

        return cell
    }
}
