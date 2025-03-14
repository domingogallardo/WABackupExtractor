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
    var chatId: Int?
    var allChats = false
}

// Main application

// Initialize the API
let api: WABackup = WABackup()

// Fetch backups
var availableBackups: [IPhoneBackup] = []
do {
    let fetchedBackups =  try api.getBackups()
    availableBackups = fetchedBackups.validBackups
    // Print invalid backups
    for url in fetchedBackups.invalidBackups {
        print("Invalid backup in: \(url.path)")
    }
} catch {
    fatalError("Error: Failed to fetch backups: \(error)")
}

// Let the user select and confirm the backup
guard let backupToUse = selectBackup(availableBackups: availableBackups) else {
    fatalError("No backup selected")
}

// Now parse command line options and set up output directories
let userOptions: UserOptions = parseCommandLineArguments()
let outputDirectoryURL = getOutputDirectoryURL(userOptions: userOptions)
createDirectory(url: outputDirectoryURL)
let outputContactDirectoryURL = outputDirectoryURL.appendingPathComponent("contacts", isDirectory: true)
createDirectory(url: outputContactDirectoryURL)

do {
    let waDatabase = try api.connectChatStorageDb(from: backupToUse)
    let chats: [ChatInfo] = try api.getChats(from: waDatabase)
    var contacts: [ContactInfo] = try api.getContacts(chats: chats, directoryToSaveMedia: outputContactDirectoryURL, from: waDatabase)
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
    if availableBackups.isEmpty {
        print("No hay backups disponibles.")
        return nil
    }
    
    // Si solo hay un backup, se selecciona automáticamente sin pedir confirmación
    if availableBackups.count == 1 {
        let onlyBackup = availableBackups.first!
        print("Solo hay un backup disponible. Seleccionando automáticamente el backup con ID \(onlyBackup.identifier) y fecha \(onlyBackup.creationDate).")
        return onlyBackup
    }
    
    print("Se encontraron los siguientes backups:")
    for (index, backup) in availableBackups.enumerated() {
        print("\(index + 1)) ID: \(backup.identifier) - Fecha: \(backup.creationDate)")
    }
    
    while true {
        print("Introduce el número del backup que deseas usar:")
        if let input = readLine(), let selectedIndex = Int(input), selectedIndex >= 1 && selectedIndex <= availableBackups.count {
            let selectedBackup = availableBackups[selectedIndex - 1]
            print("Has seleccionado el backup con ID \(selectedBackup.identifier) y fecha \(selectedBackup.creationDate). ¿Confirmas? (s/n)")
            if let confirmation = readLine(), confirmation.lowercased() == "s" || confirmation.isEmpty {
                return selectedBackup
            } else {
                print("Selección cancelada. Por favor, vuelve a seleccionar.")
            }
        } else {
            print("Entrada inválida. Debes introducir un número entre 1 y \(availableBackups.count).")
        }
    }
}

func saveChatsInfo(chats: [ChatInfo], to outputDirectoryURL: URL) {
    let outputFilename = "chats.json"
    let outputUrl = outputDirectoryURL.appendingPathComponent(outputFilename, isDirectory: false)
    outputJSON(data: chats, to: outputUrl)
}

func saveContactsInfo(contacts: [ContactInfo], to outputDirectoryURL: URL) {
    let outputFilename = "contacts.json"
    let outputUrl = outputDirectoryURL.appendingPathComponent(outputFilename, isDirectory: false)
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
