//
//  main.swift
//
//
//  Created by Domingo Gallardo on 24/05/23.
//

import Foundation
import SwiftWABackupAPI


func printUsage() {
    print("Usage: WABackupViewer -o <output_filename>")
}

var outputFilename = "chats.json" // Default output filename

// Parse command line arguments
for i in 0..<CommandLine.arguments.count {
    switch CommandLine.arguments[i] {
    case "-o":
        if i + 1 < CommandLine.arguments.count {
            outputFilename = CommandLine.arguments[i + 1]
        } else {
            print("Error: -o flag requires a subsequent filename argument")
            printUsage()
            exit(1)
        }
    default:
        if i != 0 { // Ignore the program name itself
            print("Error: Unexpected argument \(CommandLine.arguments[i])")
            printUsage()
            exit(1)
        }
    }
}

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
            let outputUrl = URL(fileURLWithPath: outputFilename)
            try jsonString.write(toFile: outputUrl.path, atomically: true, encoding: .utf8)
            print("Info about \(chats.count) chats saved to file \(outputFilename)")
        } catch {
            print("Failed to save chats info: \(error)")
        }
    } else {
        print("Failed to convert JSON data to string")
    }
} catch {
    print("Failed to encode chats to JSON: \(error)")
}