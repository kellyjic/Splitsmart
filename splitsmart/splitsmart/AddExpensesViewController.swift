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
        

        guard let groupId = group?.id else { return }

        guard let title = expenseNameField.text,
              let amountText = amountField.text,
              let amount = Double(amountText) else {
            print("Invalid input")
            return
        }

        let amountCents = Int(amount * 100)
        let splitCount = selectedMembers.count
        let splitAmount = amountCents / splitCount

        guard let payer = selectedPayer else { return }

        db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .addDocument(data: [

                "title": title,
                "amountCents": amountCents,
                "paidBy": payer,
                "members": selectedMembers,
                "splitAmount": splitAmount
            ]) { error in

                if let error = error {
                    print("Error saving expense:", error)
                } else {
                    print("Expense saved")
                    self.dismiss(animated: true)
                }
            }
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
