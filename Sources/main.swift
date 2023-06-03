//
//  main.swift
//
//
//  Created by Domingo Gallardo on 24/05/23.
//

import SwiftWABackupAPI

for argument in CommandLine.arguments {
    print("Argument: \(argument)")
}

let api = WABackup()

if let backups = api.getLocalBackups() {
    print("Found backups")
    for backup in backups {
        print("    ID: \(backup.identifier) Date: \(backup.creationDate)")
    }
    let mostRecentBackup = backups.sorted(by: { $0.creationDate > $1.creationDate }).first!
    print("Connecting to the most recent backup: \(mostRecentBackup.identifier)")
    api.connectChatStorage(backupPath: mostRecentBackup.path)
    print("Connected to the most recent backup")
    if let chats = api.getChats() {
        print("Found \(chats.count) chats")
        for chat in chats {
            print(chat)
        }
    } else {
        print("No chats")
    }
} else {
    print("No local backups")
}

