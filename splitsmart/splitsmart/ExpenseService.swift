//
//  ExpenseService.swift
//  splitsmart
//
//  Created by Olivia Kim on 3/7/26.
//

import FirebaseFirestore
import FirebaseAuth

class ExpenseService {

    static let shared = ExpenseService()
    private let db = Firestore.firestore()
    
    func addExpense(groupId: String, title: String, amount: Int) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        let data: [String: Any] = [
            "title": title,
            "amountCents": amount,
            "paidBy": uid,
            "createdBy": uid,
            "createdAt": FieldValue.serverTimestamp(),
            "status": "open"
        ]

        db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .addDocument(data: data)
    }
}
