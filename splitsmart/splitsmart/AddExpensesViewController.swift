//
//  AddExpensesViewController.swift
//  splitsmart
//
//  Created by Kelly Chang on 2026/3/10.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class AddExpensesViewController: UIViewController {

    var group: Group?
    var members: [String] = []
    var selectedMembers: [String] = []
    var selectedPayer: String?

    let db = Firestore.firestore()
    var onExpenseSaved: (() -> Void)?
    
    @IBOutlet weak var expenseNameField: UITextField!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var payerPicker: UISegmentedControl!
    @IBOutlet weak var splitTableView: UITableView!

    
    @IBAction func confirmExpenseTapped(_ sender: UIButton) {
        saveExpense()
    }
    
    @IBAction func payerChanged(_ sender: UISegmentedControl) {

        let index = sender.selectedSegmentIndex
        selectedPayer = members[index]
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitTableView.dataSource = self
        splitTableView.delegate = self

        setupPayerSegments()
        selectedMembers = members
        splitTableView.reloadData()
    }
    
    func setupPayerSegments() {

        payerPicker.removeAllSegments()

        for (index, member) in members.enumerated() {
            payerPicker.insertSegment(withTitle: member, at: index, animated: false)
        }

        if members.count > 0 {
            payerPicker.selectedSegmentIndex = 0
            selectedPayer = members[0]
        }
    }
    
    func saveExpense() {
        guard let groupId = group?.id else {
            presentAlert(title: "Missing group", message: "Try reopening the group and adding the expense again.")
            return
        }
        print("💾 Saving expense to groupId: \(groupId)")  // ← add this
            print("👥 selectedMembers: \(selectedMembers)")
            print("💰 payer: \(selectedPayer ?? "nil")")
        guard let title = expenseNameField.text,
              let amountText = amountField.text,
              let amount = Double(amountText) else {
            presentAlert(title: "Invalid input", message: "Enter an expense name and a valid amount.")
            return
        }

        let amountCents = Int(amount * 100)
        let splitCount = selectedMembers.count
        guard splitCount > 0 else {
            presentAlert(title: "No members selected", message: "Select at least one member to split the expense.")
            return
        }

        let splitAmount = amountCents / splitCount

        guard let payer = selectedPayer else {
            presentAlert(title: "Missing payer", message: "Choose who paid for this expense.")
            return
        }

        db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .addDocument(data: [

                "title": title,
                "amountCents": amountCents,
                "paidBy": payer,
                "members": selectedMembers,
                "splitAmount": splitAmount,
                "status": "open",
                "createdAt": FieldValue.serverTimestamp()
            ]) { error in

                if let error = error {
                    self.presentAlert(title: "Could not save expense", message: error.localizedDescription)
                } else {
                    self.navigateBackAfterSave()
                }
            }
    }

    private func navigateBackAfterSave() {
        onExpenseSaved?()
        if let navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


extension AddExpensesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return members.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .default, reuseIdentifier: "memberCell")

        let member = members[indexPath.row]
        cell.textLabel?.text = member

        if selectedMembers.contains(member) {
            cell.accessoryType = .checkmark
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        let member = members[indexPath.row]

        if selectedMembers.contains(member) {
            selectedMembers.removeAll { $0 == member }
        } else {
            selectedMembers.append(member)
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
