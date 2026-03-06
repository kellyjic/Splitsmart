Design Firestore structure (collections + fields)

Database Collection (automatically creates from code)

1. Collection: users {uid}
    
    users/{uid} {
      displayName: "Parshvi",
      email: "p@uw.edu",
      createdAt: serverTimestamp()
    }
        
2. Collection Group

    groups/{groupId} {
      name: "Disney Trip",
      createdBy: uid,
      createdAt: serverTimestamp(),
      currency: "USD",
      joinCode: "b37sj2",
      isActive: true
    }

3. Subcollection: groups/{groupId}/members
Doc ID = uid (simple + secure)

    groups/{groupId}/members/{uid} {
      role: "admin",
      joinedAt: serverTimestamp()
    }

4. Subcollection: groups/{groupId}/expenses
Each expense is something like “Train Tickets”, “Costco”, etc

    groups/{groupId}/expenses/{expenseId} {
      title: "Train Tickets",
      amountCents: 12000,
      currency: "USD",
      paidBy: uid,                  // who paid
      createdBy: uid,               // who entered it
      createdAt: serverTimestamp(),
      note: "",
      status: "open" | "settled" | "deleted"
    }

6. Subcollection: groups/{groupId}/expenses/{expenseId}/splits
Who owes for this expense (supports uneven splits/weights)
Doc ID can be debtor uid.

    groups/{groupId}/expenses/{expenseId}/splits/{debtorUid} {
      owedCents: 3000
    }
    
7. Subcollection: groups/{groupId}/settlements
This is your “I Paid!” / mark settled flow (Payment Status screen).

    groups/{groupId}/settlements/{settlementId} {
      expenseId: expenseId,
      fromUid: debtorUid,
      toUid: paidByUid,
      amountCents: 3000,
      status: "unpaid",
      createdAt: serverTimestamp()
    }
