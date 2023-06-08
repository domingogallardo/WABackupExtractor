//
//  main.swift
//
//
//  Created by Domingo Gallardo on 24/05/23.
//

import Foundation
import SwiftWABackupAPI

let api = WABackup()

let backups = api.getLocalBackups()

guard backups.count > 0 else {
    print("No local backups")
    exit(1)
}

/*
for backup in backups {
    print("    ID: \(backup.identifier) Date: \(backup.creationDate)")
}
*/

let mostRecentBackup = backups.sorted(by: { $0.creationDate > $1.creationDate }).first!
if api.connectChatStorageDb(from: mostRecentBackup) {
    if let chats = api.getChats(from: mostRecentBackup) {

        // Encoding chats to JSON
        let jsonEncoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        jsonEncoder.dateEncodingStrategy = .formatted(formatter)
        jsonEncoder.outputFormatting = .prettyPrinted // Optional: if you want the JSON output to be indented
        do {
            let jsonData = try jsonEncoder.encode(chats)

            let jsonString = String(data: jsonData, encoding: .utf8)
            print(jsonString ?? "Failed to convert JSON data to string")
        } catch {
            print("Failed to encode chats to JSON: \(error)")
        }
    } else {
        print("No chats")
    }
} else {
    print("Failed to connect to the most recent backup")
}

