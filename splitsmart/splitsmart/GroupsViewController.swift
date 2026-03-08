//
//  GroupsViewController.swift
//  splitsmart
//
//  Created by Olivia Kim on 3/7/26.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class GroupsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var groups: [Group] = []
    let db = Firestore.firestore()
    var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshGroups), for: .valueChanged)
        tableView.refreshControl = refreshControl

        observeGroups()
    }

    deinit {
        listener?.remove()
    }

    @objc func refreshGroups() {
        tableView.refreshControl?.endRefreshing()
    }

    func observeGroups() {

        guard let email = Auth.auth().currentUser?.email else {
            print("No user email")
            return
        }

        print("Fetching groups for:", email)

        listener = db.collection("groups")
            .whereField("members", arrayContains: email)
            .addSnapshotListener { snapshot, error in

                if let error = error {
                    print("Firestore error:", error)
                    return
                }

                guard let docs = snapshot?.documents else {
                    print("No documents")
                    return
                }

                print("Groups found:", docs.count)

                self.groups = docs.map { doc in
                    let data = doc.data()

                    return Group(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        createdBy: data["createdBy"] as? String ?? "",
                        members: data["members"] as? [String] ?? []
                    )
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    func fetchGroups(completion: @escaping () -> Void) {
        observeGroups()
        completion()
    }

    @IBAction func addEventTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToAddEvent", sender: nil)
    }

    @IBAction func joinGroupTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Join Group", message: "Enter Event ID", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Event ID" }

        let joinAction = UIAlertAction(title: "Join", style: .default) { _ in
            guard let code = alert.textFields?.first?.text, !code.isEmpty else { return }
            self.joinGroup(with: code)
        }

        alert.addAction(joinAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func joinGroup(with code: String) {

        guard let email = Auth.auth().currentUser?.email else { return }

        db.collection("groups")
            .whereField("joinCode", isEqualTo: code)
            .getDocuments { snapshot, error in

                if let error = error {
                    print("Join group error:", error)
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("Group not found")
                    return
                }

                let groupId = document.documentID

                self.db.collection("groups")
                    .document(groupId)
                    .updateData([
                        "members": FieldValue.arrayUnion([email])
                    ]) { error in

                        if let error = error {
                            print("Error joining group:", error)
                        } else {
                            print("Successfully joined group")
                        }
                    }
            }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToAddEvent",
           let destination = segue.destination as? AddEventViewController {
            destination.onGroupCreated = { [weak self] in
                // Optional: refresh manually
                self?.refreshGroups()
            }
        }

        if segue.identifier == "goToGroupDetail",
           let destination = segue.destination as? GroupDetailViewController {
            destination.group = sender as? Group
        }
    }
}

extension GroupsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath)

        guard indexPath.row < groups.count else {
            return cell
        }

        let group = groups[indexPath.row]
        cell.textLabel?.text = group.name

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = groups[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "goToGroupDetail", sender: group)
    }
}
