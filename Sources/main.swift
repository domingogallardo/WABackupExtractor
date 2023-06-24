//
//  main.swift
//
//
//  Created by Domingo Gallardo on 24/05/23.
//

//  The aplication needs permission to access the iPhone backup in 
//   ~/Library/Application Support/MobileSync/Backup/
//  Go to System Preferences -> Security & Privacy -> Full Disk Access

import Foundation
import SwiftWABackupAPI

func printUsage() {
    print("Usage: WABackupViewer  [-b <backup_id>] [-c <chat_id>] [-o <output_filename>]")
}

var outputFilename = "chats.json" // Default output filename
var backupId: String? = nil // Variable to hold backup ID
var chatId: Int? = nil // Variable to hold chat ID

// Parse command line arguments
var i = 0
while i < CommandLine.arguments.count {
    switch CommandLine.arguments[i] {
    case "-o":
        if i + 1 < CommandLine.arguments.count {
            outputFilename = CommandLine.arguments[i + 1]
            i += 1
        } else {
            print("Error: -o flag requires a subsequent filename argument")
            printUsage()
            exit(1)
        }
    case "-b":
        if i + 1 < CommandLine.arguments.count {
            backupId = CommandLine.arguments[i + 1]
            i += 1
        } else {
            print("Error: -b flag requires a subsequent backup ID argument")
            printUsage()
            exit(1)
        }
    case "-c":
        if i + 1 < CommandLine.arguments.count {
            chatId = Int(CommandLine.arguments[i + 1])
            i += 1
        } else {
            print("Error: -c flag requires a subsequent chat ID argument")
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
    i += 1
}

let api = WABackup()
let backups = api.getLocalBackups()

// Select the backup
let selectedBackup: IPhoneBackup
if backups.count > 1 {
    print("Found backups:")
    for backup in backups {
        print("    ID: \(backup.identifier) Date: \(backup.creationDate)")
    }
    if let backupId = backupId, let backup = backups.first(where: { $0.identifier == backupId }) {
        selectedBackup = backup
        print("Using backup with ID \(backupId)")
        printUsage()
    } else if let mostRecentBackup = backups.sorted(by: { $0.creationDate > $1.creationDate }).first {
        selectedBackup = mostRecentBackup
        print("Using most recent backup with ID \(mostRecentBackup.identifier)")
        printUsage()

    } else {
        print("No backups available")
        printUsage()
        exit(1)
    }
} else if let onlyBackup = backups.first {
    selectedBackup = onlyBackup
    print("Using the only available backup with ID \(onlyBackup.identifier)")
    printUsage()
} else {
    print("No backups available")
    printUsage()
    exit(1)
}

guard api.connectChatStorageDb(from: selectedBackup) else {
    print("Failed to connect to the most recent backup")
    exit(1)
}

if let chatId = chatId {
    let messages = api.getChatMessages(chatId: chatId, from: selectedBackup)
    if messages.count > 1 {
        outputMessages(messages: messages, to: "chat_\(chatId).json")
    } else {
        print ("No messages available")
        exit(1)
    }
} else {
    let chats = api.getChats(from: selectedBackup)
    if chats.count > 1 {
        outputChatsJSON(chats: chats, to: outputFilename)
    } else {
        print ("No chats available")
        exit(1)
    }    
}

func outputMessages(messages: [MessageInfo], to outputFilename: String) {
    let jsonEncoder = JSONEncoder()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    jsonEncoder.dateEncodingStrategy = .formatted(formatter)
    jsonEncoder.outputFormatting = .prettyPrinted // Optional: if you want the JSON output to be indented

    do {
        let jsonData = try jsonEncoder.encode(messages)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            do {
                let outputUrl = URL(fileURLWithPath: outputFilename)
                try jsonString.write(toFile: outputUrl.path, atomically: true, encoding: .utf8)
                print(">>> \(messages.count) messages saved to file \(outputFilename)")
            } catch {
                print("Failed to save messages: \(error)")
            }
        } else {
            print("Failed to convert JSON data to string")
        }
    } catch {
        print("Failed to encode chats to JSON: \(error)")
    }
}

func outputChatsJSON(chats: [ChatInfo], to outputFilename: String) {
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
                print(">>> Info about \(chats.count) chats saved to file \(outputFilename)")
            } catch {
                print("Failed to save chats info: \(error)")
            }
        } else {
            print("Failed to convert JSON data to string")
        }
    } catch {
        print("Failed to encode chats to JSON: \(error)")
    }
}
