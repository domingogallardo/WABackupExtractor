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
    print("Usage: WABackupViewer  [-b <backup_id>] [-c <chat_id>] [-o <output_directory>]")
}

var outputDirectory = "WABackup" // Default output directory
var backupId: String? = nil // Variable to hold backup ID
var chatId: Int? = nil // Variable to hold chat ID

// Parse command line arguments
var i = 0
while i < CommandLine.arguments.count {
    switch CommandLine.arguments[i] {
    case "-o":
        if i + 1 < CommandLine.arguments.count {
            outputDirectory = CommandLine.arguments[i + 1]
            i += 1
        } else {
            print("Error: -o flag requires a subsequent directory name argument")
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

let outputDirectoryPath: String
if outputDirectory.hasPrefix("/") {
    outputDirectoryPath = outputDirectory
} else {
    outputDirectoryPath = FileManager.default.currentDirectoryPath + "/" + outputDirectory
}

do {
    try FileManager.default.createDirectory(atPath: outputDirectoryPath, withIntermediateDirectories: true)
} catch {
    print("Error: Failed to create output directory \(outputDirectory): \(error)")
    exit(1)
}

let api = WABackup()
let availableBackups = api.getLocalBackups()

let backupToUse: IPhoneBackup
if availableBackups.count > 1 {
    print("Found backups:")
    for backup in availableBackups {
        print("    ID: \(backup.identifier) Date: \(backup.creationDate)")
    }
    if let backupId = backupId, let backup = availableBackups.first(where: { $0.identifier == backupId }) {
        backupToUse = backup
        print("Using backup with ID \(backupId)")
        printUsage()
    } else if let mostRecentBackup = availableBackups.sorted(by: { $0.creationDate > $1.creationDate }).first {
        backupToUse = mostRecentBackup
        print("Using most recent backup with ID \(mostRecentBackup.identifier)")
        printUsage()

    } else {
        print("No backups available")
        printUsage()
        exit(1)
    }
} else if let onlyBackup = availableBackups.first {
    backupToUse = onlyBackup
    print("Using the only available backup with ID \(onlyBackup.identifier)")
    printUsage()
} else {
    print("No backups available")
    printUsage()
    exit(1)
}

guard api.connectChatStorageDb(from: backupToUse) else {
    print("Failed to connect to the most recent backup")
    exit(1)
}

if let chatId = chatId {
    let messages = api.getChatMessages(chatId: chatId, from: backupToUse)
    if messages.count > 1 {
        let outputFilename = "chat_\(chatId).json"
        outputMessagesJSON(messages: messages, to: outputFilename)
    } else {
        print ("No messages available")
        exit(1)
    }
} else {
    let chats = api.getChats(from: backupToUse)
    if chats.count > 1 {
        let outputFilename = "chats.json"
        outputChatsJSON(chats: chats, to: outputFilename)
    } else {
        print ("No chats available")
        exit(1)
    }    
}

func outputMessagesJSON(messages: [MessageInfo], to outputFilename: String) {
    let jsonEncoder = JSONEncoder()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    jsonEncoder.dateEncodingStrategy = .formatted(formatter)
    jsonEncoder.outputFormatting = .prettyPrinted // Optional: if you want the JSON output to be indented

    do {
        let jsonData = try jsonEncoder.encode(messages)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            do {
                let outputUrl = URL(fileURLWithPath: outputDirectoryPath).appendingPathComponent(outputFilename)
                try jsonString.write(toFile: outputUrl.path, atomically: true, encoding: .utf8)
                print(">>> \(messages.count) messages saved to file \(outputUrl.path)")
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
                let outputUrl = URL(fileURLWithPath: outputDirectoryPath).appendingPathComponent(outputFilename)
                try jsonString.write(toFile: outputUrl.path, atomically: true, encoding: .utf8)
                print(">>> Info about \(chats.count) chats saved to file \(outputUrl.path)")
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
