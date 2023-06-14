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
    print("No backups")
    exit(1)
}

print("Found backups:")

for backup in backups {
    print("    ID: \(backup.identifier) Date: \(backup.creationDate)")
}

guard let mostRecentBackup = backups.sorted(by: { $0.creationDate > $1.creationDate }).first else {
    print("No backups available")
    exit(1)
}

guard api.connectChatStorageDb(from: mostRecentBackup) else {
    print("Failed to connect to the most recent backup")
    exit(1)
}

let chats = api.getChats(from: mostRecentBackup)

guard !chats.isEmpty  else {
    print("No chats")
    exit(1)
}

print("Most recent backup: \(mostRecentBackup.creationDate)")

// Encoding chats to JSON
let jsonEncoder = JSONEncoder()
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
jsonEncoder.dateEncodingStrategy = .formatted(formatter)
jsonEncoder.outputFormatting = .prettyPrinted // Optional: if you want the JSON output to be indented

do {
    let jsonData = try jsonEncoder.encode(chats)
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        do {
            try jsonString.write(toFile: "chats.json", atomically: true, encoding: .utf8)
            print("Info about \(chats.count) chats saved to file chats.json")
        } catch {
            print("Failed to save chats info: \(error)")
        }
    } else {
        print("Failed to convert JSON data to string")
    }
} catch {
    print("Failed to encode chats to JSON: \(error)")
}

