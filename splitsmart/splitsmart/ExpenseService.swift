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

    private init() {}

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

    func fetchExpenses(
        groupId: String,
        groupName: String? = nil,
        completion: @escaping (Result<[Expense], Error>) -> Void
    ) {
        db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let expenses = snapshot?.documents.compactMap {
                    self.makeExpense(from: $0, groupId: groupId, groupName: groupName)
                } ?? []

                completion(.success(expenses))
            }
    }

    func fetchExpensesForCurrentUser(completion: @escaping (Result<[Expense], Error>) -> Void) {
        guard let email = Auth.auth().currentUser?.email else {
            let error = NSError(
                domain: "ExpenseService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No logged in user email."]
            )
            completion(.failure(error))
            return
        }

        db.collection("groups")
            .whereField("members", arrayContains: email)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let documents = snapshot?.documents ?? []
                if documents.isEmpty {
                    completion(.success([]))
                    return
                }

                var fetchedExpenses: [Expense] = []
                let dispatchGroup = DispatchGroup()
                var capturedError: Error?

                for document in documents {
                    dispatchGroup.enter()

                    let groupName = document.data()["name"] as? String
                    self.fetchExpenses(groupId: document.documentID, groupName: groupName) { result in
                        switch result {
                        case .success(let expenses):
                            fetchedExpenses.append(contentsOf: expenses)
                        case .failure(let error):
                            capturedError = error
                        }

                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    if let capturedError {
                        completion(.failure(capturedError))
                        return
                    }

                    let sortedExpenses = fetchedExpenses.sorted {
                        ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
                    }
                    completion(.success(sortedExpenses))
                }
            }
    }

    func updateExpense(
        groupId: String,
        expenseId: String,
        title: String,
        amountCents: Int,
        splitCount: Int,
        completion: @escaping (Error?) -> Void
    ) {
        let safeSplitCount = max(splitCount, 1)
        let splitAmount = amountCents / safeSplitCount

        db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .document(expenseId)
            .updateData([
                "title": title,
                "amountCents": amountCents,
                "splitAmount": splitAmount
            ], completion: completion)
    }

    func deleteExpense(groupId: String, expenseId: String, completion: @escaping (Error?) -> Void) {
        db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .document(expenseId)
            .delete(completion: completion)
    }

    func markExpenseSettled(groupId: String, expenseId: String, completion: @escaping (Error?) -> Void) {
        db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .document(expenseId)
            .updateData([
                "status": "settled",
                "settledAt": FieldValue.serverTimestamp()
            ], completion: completion)
    }

    private func makeExpense(
        from document: QueryDocumentSnapshot,
        groupId: String,
        groupName: String?
    ) -> Expense {
        let data = document.data()
        let timestamp = data["createdAt"] as? Timestamp
        let members = data["members"] as? [String] ?? []
        let amountCents = data["amountCents"] as? Int ?? data["splitAmount"] as? Int ?? 0
        let splitAmount = data["splitAmount"] as? Int ?? amountCents

        return Expense(
            id: document.documentID,
            title: data["title"] as? String ?? "",
            amountCents: amountCents,
            paidBy: data["paidBy"] as? String ?? "",
            groupId: groupId,
            groupName: groupName,
            members: members,
            splitAmount: splitAmount,
            status: data["status"] as? String ?? "open",
            createdAt: timestamp?.dateValue()
        )
    }
}
