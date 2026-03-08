import FirebaseFirestore
import FirebaseAuth

class GroupService {

    static let shared = GroupService()
    private let db = Firestore.firestore()

    func createGroup(name: String, completion: @escaping (_ joinCode: String?, _ error: Error?) -> Void) {

        guard let user = Auth.auth().currentUser else { return }

        let uid = user.uid
        let email = user.email ?? "unknown@example.com"

        let groupRef = db.collection("groups").document()
        let joinCode = generateRandomCode()

        groupRef.setData([
            "name": name,
            "createdBy": uid,
            "joinCode": joinCode,
            "members": [email], 
            "createdAt": FieldValue.serverTimestamp()
        ]) { error in

            if let error = error {
                completion(nil, error)
                return
            }

            completion(joinCode, nil)
        }
    }

    private func generateRandomCode(length: Int = 6) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}
