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
let outputContactDirectoryURL = outputDirectoryURL.appendingPathComponent("contacts", isDirectory: true)
createDirectory(url: outputContactDirectoryURL)

let api: WABackup = WABackup()
let handler = WABackupHandler()
api.delegate = handler

var availableBackups: [IPhoneBackup] = []

do {
    let fetchedBackups =  try api.getBackups()
    availableBackups = fetchedBackups.validBackups
    
    // print URLs of invalid backups
    for url in fetchedBackups.invalidBackups {
        print("Invalid backup in: \(url.path)")
}
} catch {
    fatalError("Error: Failed to fetch backups: \(error)")
}

guard let backupToUse = selectBackup(availableBackups: availableBackups) else {
    fatalError("No backup selected")
}

do {
    let waDatabase = try api.connectChatStorageDb(from: backupToUse)
    let chats: [ChatInfo] = try api.getChats(from: waDatabase)
    var contacts: [ProfileInfo] = try api.getProfiles(directoryToSaveMedia: outputContactDirectoryURL, 
                                                from: waDatabase)
    if let userProfile = try api.getUserProfile(directoryToSaveMedia: outputContactDirectoryURL, from: waDatabase) {
        contacts.append(userProfile)
    }

    if let chatId = userOptions.chatId {
        saveChatMessages(for: chatId, 
                         with: outputDirectoryURL, 
                         from: backupToUse,
                         chats: chats,
                         waDatabase: waDatabase)
    } else {
        if chats.count > 0 {
            saveChatsInfo(chats: chats, to: outputDirectoryURL)
            saveContactsInfo(contacts: contacts, to: outputDirectoryURL)
            if userOptions.allChats {
                for chat in chats {
                    saveChatMessages(for: chat.id, 
                                     with: outputDirectoryURL, 
                                     from: backupToUse, 
                                     chats: chats, 
                                     waDatabase: waDatabase)
                }
            }
        } else {
            fatalError ("No chats available")
        }    
    }
} catch {
    fatalError("Error: \(error)")
}


// Auxiliary functions

func printUsage() {
    print("Usage: WABackupViewer  [-b <backup_id>] [-c <chat_id>] [-o <output_directory>]")
}

func getFlagArgument(currentIndex: Int, flag: String) -> String? {
    if currentIndex + 1 < CommandLine.arguments.count {
        return CommandLine.arguments[currentIndex + 1]
    } else {
        printUsage()
        fatalError("Error: \(flag) flag requires a subsequent argument")
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
                    printUsage()
                    fatalError("Error: Invalid chat ID \(chatIdStr)")
                }
                userOptions.chatId = chatId
                i += 1
            }
        case "-all":
            userOptions.allChats = true
            userOptions.chatId = nil
        default:
            if i != 0 { // Ignore the program name itself
                printUsage()
                fatalError("Error: Unexpected argument \(CommandLine.arguments[i])")
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
        fatalError("Error: Failed to create output directory \(url): \(error)")
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

func saveContactsInfo(contacts: [ProfileInfo], to outputDirectoryURL: URL) {
    let outputFilename = "contacts.json"
    let outputUrl = outputContactDirectoryURL.appendingPathComponent(outputFilename, isDirectory: false)
    outputJSON(data: contacts, to: outputUrl)
}

func saveChatMessages(for chatId: Int, 
                      with directoryURL: URL, 
                      from backupToUse: IPhoneBackup,
                      chats: [ChatInfo],
                      waDatabase: WADatabase) {
    let numberMessages = chats.filter { $0.id == chatId }.first?.numberMessages ?? 0
    if numberMessages > 0 {
        let chatDirectoryURL = directoryURL.appendingPathComponent("chat_\(chatId)", isDirectory: true)
        createDirectory(url: chatDirectoryURL)
        handler.directoryToSaveMedia = chatDirectoryURL.path
        let messages = try! api.getChatMessages(chatId: chatId, directoryToSaveMedia: chatDirectoryURL, from: waDatabase)
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
