//
//  Expense.swift
//  splitsmart
//
//  Created by Olivia Kim on 3/7/26.
//

import Foundation

struct Expense {
    var id: String
    var title: String
    var amountCents: Int
    var paidBy: String
    var groupId: String? = nil
    var groupName: String? = nil
    var members: [String] = []
    var splitAmount: Int = 0
    var status: String = "open"
    var createdAt: Date? = nil

    var isSettled: Bool {
        status == "settled"
    }
}
