//
//  UserService.swift
//  splitsmart
//
//  Created by Parshvi Balu on 3/5/26.
//

import Foundation
import FirebaseFirestore

final class UserService {
    static let shared = UserService()

    private let db = Firestore.firestore()

    private init() {}

    func createUserDocument(uid: String, email: String, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(uid).setData(data, merge: true) { error in
            completion(error)
        }
    }
}
