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
let outputDirectoryURL = getOutputDirectoryURL(userOptions: userOptions)
createDirectory(url: outputDirectoryURL)
let outputProfileDirectoryURL = outputDirectoryURL.appendingPathComponent("profiles", isDirectory: true)
createDirectory(url: outputProfileDirectoryURL)

let api: WABackup = WABackup()
let handler = WABackupHandler()
api.delegate = handler

let availableBackups: [IPhoneBackup] = api.getLocalBackups()

guard let backupToUse = selectBackup(availableBackups: availableBackups) else {
    print("No backup selected")
    exit(1)
}

guard let waDatabase = api.connectChatStorageDb(from: backupToUse) else {
    print("Failed to connect to the most recent backup")
    exit(1)
}

let chats: [ChatInfo] = api.getChats(from: waDatabase)
var profiles: [ProfileInfo] = api.getProfiles(directoryToSaveMedia: outputProfileDirectoryURL, 
                                              from: waDatabase)
if let userProfile = api.getUserProfile(directoryToSaveMedia: outputProfileDirectoryURL, from: waDatabase) {
    profiles.append(userProfile)
}

if let chatId = userOptions.chatId {
    saveChatMessages(for: chatId, with: outputDirectoryURL, from: backupToUse)
} else {
    if chats.count > 0 {
        saveChatsInfo(chats: chats, to: outputDirectoryURL)
        saveProfilesInfo(profiles: profiles, to: outputDirectoryURL)
        if userOptions.allChats {
            for chat in chats {
                saveChatMessages(for: chat.id, with: outputDirectoryURL, from: backupToUse)
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

func getOutputDirectoryURL(userOptions: UserOptions) -> URL {
    let defaultOutputDirectory = "WABackup"
    let outputDirectoryPath = userOptions.outputDirectory ?? defaultOutputDirectory
    var outputDirectoryURL: URL
    if outputDirectoryPath.hasPrefix("/") {
        outputDirectoryURL = URL(fileURLWithPath: outputDirectoryPath)
    } else {
        outputDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(outputDirectoryPath, isDirectory: true)
    }
    return outputDirectoryURL
}

func createDirectory(url: URL) {
    do {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    } catch {
        print("Error: Failed to create output directory \(url): \(error)")
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

func saveChatsInfo(chats: [ChatInfo], to outputDirectoryURL: URL) {
    let outputFilename = "chats.json"
    let outputUrl = outputDirectoryURL.appendingPathComponent(outputFilename, isDirectory: false)
    outputJSON(data: chats, to: outputUrl)
}

func saveProfilesInfo(profiles: [ProfileInfo], to outputDirectoryURL: URL) {
    let outputFilename = "profiles.json"
    let outputUrl = outputProfileDirectoryURL.appendingPathComponent(outputFilename, isDirectory: false)
    outputJSON(data: profiles, to: outputUrl)
}

func saveChatMessages(for chatId: Int, with directoryURL: URL, from backupToUse: IPhoneBackup) {
    let numberMessages = chats.filter { $0.id == chatId }.first?.numberMessages ?? 0
    if numberMessages > 0 {
        let chatDirectoryURL = directoryURL.appendingPathComponent("chat_\(chatId)", isDirectory: true)
        createDirectory(url: chatDirectoryURL)
        handler.directoryToSaveMedia = chatDirectoryURL.path
        let messages = api.getChatMessages(chatId: chatId, directoryToSaveMedia: chatDirectoryURL, from: waDatabase)
        let outputFilename = "chat_\(chatId).json"
        let outputUrl = chatDirectoryURL.appendingPathComponent(outputFilename, isDirectory: false)
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
