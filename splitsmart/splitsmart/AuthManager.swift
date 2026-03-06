//
//  AuthManager.swift
//  splitsmart
//
//  Created by Parshvi Balu on 3/5/26.
//

import Foundation
import FirebaseAuth

final class AuthManager {
    static let shared = AuthManager()

    private init() {}

    func createUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user else {
                let customError = NSError(domain: "AuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user returned"])
                completion(.failure(customError))
                return
            }

            completion(.success(user))
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user else {
                let customError = NSError(domain: "AuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user returned"])
                completion(.failure(customError))
                return
            }

            completion(.success(user))
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
