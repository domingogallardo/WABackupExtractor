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

struct UserOptions {
    var outputDirectory: String? 
    var backupId: String? 
    var chatId: Int? 
    var allChats = false 
}

class WABackupHandler: WABackupDelegate {
    var directoryToSaveMedia: String?

    func didWriteMediaFile(fileName: String) {
        /*
        if let directoryToSaveMedia = directoryToSaveMedia {
            print(">>> Media file written: \(directoryToSaveMedia)/\(fileName)")
        } else {
            print(">>> Media file written: \(fileName)")
        }
        */
    }
}

// Main application

let userOptions: UserOptions = parseCommandLineArguments()
let outputDirectoryPath = getOutputDirectoryPath(userOptions: userOptions)
createDirectory(path: outputDirectoryPath)
let outputProfileDirectoryURL = URL(fileURLWithPath: outputDirectoryPath).appendingPathComponent("profiles")
createDirectory(path: outputProfileDirectoryURL.path)

let api: WABackup = WABackup()
let handler = WABackupHandler()
api.delegate = handler

let availableBackups: [IPhoneBackup] = api.getLocalBackups()

guard let backupToUse = selectBackup(availableBackups: availableBackups) else {
    print("No backup selected")
    exit(1)
}

guard api.connectChatStorageDb(from: backupToUse) else {
    print("Failed to connect to the most recent backup")
    exit(1)
}

let chats: [ChatInfo] = api.getChats(from: backupToUse)
let profiles: [ProfileInfo] = api.getProfiles(directoryToSaveMedia: outputProfileDirectoryURL, 
                                              from: backupToUse)

if let chatId = userOptions.chatId {
    saveChatMessages(for: chatId, with: outputDirectoryPath, from: backupToUse)
} else {
    if chats.count > 0 {
        saveChatsInfo(chats: chats, to: outputDirectoryPath)
        saveProfilesInfo(profiles: profiles, to: outputDirectoryPath)
        if userOptions.allChats {
            for chat in chats {
                saveChatMessages(for: chat.id, with: outputDirectoryPath, from: backupToUse)
            }
        }
    } else {
        print ("No chats available")
        exit(1)
    }    
}

// Auxiliary functions

func printUsage() {
    print("Usage: WABackupViewer  [-b <backup_id>] [-c <chat_id>] [-o <output_directory>]")
}

func getFlagArgument(currentIndex: Int, flag: String) -> String? {
    if currentIndex + 1 < CommandLine.arguments.count {
        return CommandLine.arguments[currentIndex + 1]
    } else {
        print("Error: \(flag) flag requires a subsequent argument")
        printUsage()
        exit(1)
    }
}

func parseCommandLineArguments() -> UserOptions {
    var i = 0
    var userOptions = UserOptions()
    while i < CommandLine.arguments.count {
        switch CommandLine.arguments[i] {
        case "-o":
            userOptions.outputDirectory = getFlagArgument(currentIndex: i, flag: "-o") ?? userOptions.outputDirectory
            i += 1
        case "-b":
            userOptions.backupId = getFlagArgument(currentIndex: i, flag: "-b")
            i += 1
        case "-c":
            if let chatIdStr = getFlagArgument(currentIndex: i, flag: "-c") {
                guard let chatId = Int(chatIdStr) else {
                    print("Error: Invalid chat ID \(chatIdStr)")
                    printUsage()
                    exit(1)
                }
                userOptions.chatId = chatId
                i += 1
            }
        case "-all":
            userOptions.allChats = true
            userOptions.chatId = nil
        default:
            if i != 0 { // Ignore the program name itself
                print("Error: Unexpected argument \(CommandLine.arguments[i])")
                printUsage()
                exit(1)
            }
        }
        i += 1
    }
    return userOptions
}

func getOutputDirectoryPath(userOptions: UserOptions) -> String {
    let defaultOutputDirectory = "WABackup"
    let outputDirectory = userOptions.outputDirectory ?? defaultOutputDirectory
    var outputDirectoryPath: String
    if outputDirectory.hasPrefix("/") {
        outputDirectoryPath = outputDirectory
    } else {
        outputDirectoryPath = FileManager.default.currentDirectoryPath + "/" + outputDirectory
    }
    return outputDirectoryPath
}

func createDirectory(path: String) {
    do {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    } catch {
        print("Error: Failed to create output directory \(path): \(error)")
        exit(1)
    }
}

func selectBackup(availableBackups: [IPhoneBackup]) -> IPhoneBackup? {
    if availableBackups.count > 1 {
        print("Found backups:")
        for backup in availableBackups {
            print("    ID: \(backup.identifier) Date: \(backup.creationDate)")
        }
        print("Enter the ID of the backup to use:")
        if let backupId = readLine() {
            return availableBackups.first(where: { $0.identifier == backupId })
        } else {
            print("No backup ID entered")
            return nil
        }
    } else if let onlyBackup = availableBackups.first {
        print("Using the only available backup with ID \(onlyBackup.identifier)")
        return onlyBackup
    } else {
        print("No backups available")
        return nil
    }
}

func saveChatsInfo(chats: [ChatInfo], to outputDirectoryPath: String) {
    let outputFilename = "chats.json"
    let outputUrl = URL(fileURLWithPath: outputDirectoryPath).appendingPathComponent(outputFilename)
    outputJSON(data: chats, to: outputUrl)
}

func saveProfilesInfo(profiles: [ProfileInfo], to outputDirectoryPath: String) {
    let outputFilename = "profiles.json"
    let outputUrl = outputProfileDirectoryURL.appendingPathComponent(outputFilename)
    outputJSON(data: profiles, to: outputUrl)
}

func saveChatMessages(for chatId: Int, with directoryPath: String, from backupToUse: IPhoneBackup) {
    let numberMessages = chats.filter { $0.id == chatId }.first?.numberMessages ?? 0
    if numberMessages > 0 {
        let chatDirectoryPath = directoryPath + "/chat_\(chatId)"
        createDirectory(path: chatDirectoryPath)
        let directoryUrl = URL(fileURLWithPath: chatDirectoryPath)
        handler.directoryToSaveMedia = chatDirectoryPath
        let messages = api.getChatMessages(chatId: chatId, directoryToSaveMedia: directoryUrl, from: backupToUse)
        let outputFilename = "chat_\(chatId).json"
        let outputUrl = directoryUrl.appendingPathComponent(outputFilename)
        outputJSON(data: messages, to: outputUrl)
    } else {
        print("No messages in chat \(chatId)")
    }
}

func outputJSON<T: Encodable>(data: [T], to outputUrl: URL) {
    let jsonEncoder = JSONEncoder()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    jsonEncoder.dateEncodingStrategy = .formatted(formatter)
    jsonEncoder.outputFormatting = .prettyPrinted // Optional: if you want the JSON output to be indented

    do {
        let jsonData = try jsonEncoder.encode(data)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            do {
                try jsonString.write(toFile: outputUrl.path, atomically: true, encoding: .utf8)
                print(">>> \(data.count) items saved to file \(outputUrl.path)")
            } catch {
                print("Failed to save data: \(error)")
            }
        } else {
            print("Failed to convert JSON data to string")
        }
    } catch {
        print("Failed to encode data to JSON: \(error)")
    }
}
