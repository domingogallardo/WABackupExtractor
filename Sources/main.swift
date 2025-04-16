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

struct ChatInfoExtended: Encodable {
    let chat: ChatInfo
    let contacts: [ContactInfo]
}

// Main application
// Primero, se comprueban los argumentos de la línea de comandos
let userOptions: UserOptions = parseCommandLineArguments()

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
let outputDirectoryURL = getOutputDirectoryURL(userOptions: userOptions)
createDirectory(url: outputDirectoryURL)

do {
    try api.connectChatStorageDb(from: backupToUse)
    if let chatId = userOptions.chatId {
        // Modo de chat individual: solo se procesa el chat indicado.
        saveSingleChatMessages(for: chatId, with: outputDirectoryURL, from: backupToUse)
    } else {
        let chatsDirectoryURL = outputDirectoryURL.appendingPathComponent("Chats", isDirectory: true)
        createDirectory(url: chatsDirectoryURL)
        let chats: [ChatInfo] = try api.getChats(directoryToSavePhotos: chatsDirectoryURL)
    
        if chats.count > 0 {
            saveChatsInfo(chats: chats, to: chatsDirectoryURL)
            if userOptions.allChats {
                for chat in chats {
                    saveChatMessages(for: chat.id,
                                     with: outputDirectoryURL,
                                     from: backupToUse,
                                     chats: chats)
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
    print("Usage: WABackupViewer  [-c <chat_id>] [-all] [-o <output_directory>]")
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
    var userOptions = UserOptions()
    var i = 1 // Empezamos en 1 para omitir el nombre del programa

    while i < CommandLine.arguments.count {
        let arg = CommandLine.arguments[i]
        switch arg {
        case "-o":
            if let value = getFlagArgument(currentIndex: i, flag: "-o") {
                userOptions.outputDirectory = value
                i += 1
            }
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
            print("Error: Unexpected argument \(arg)")
            printUsage()
            exit(1)
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

func saveContactsInfo(contacts: [ContactInfo], for chatId: Int, to outputDirectoryURL: URL) {
    let outputFilename = "contacts_\(chatId).json"
    let outputUrl = outputDirectoryURL.appendingPathComponent(outputFilename, isDirectory: false)
    outputJSON(data: contacts, to: outputUrl)
}

func saveChatMessages(for chatId: Int,
                      with directoryURL: URL,
                      from backupToUse: IPhoneBackup,
                      chats: [ChatInfo]) {
    
    let numberMessages = chats.first { $0.id == chatId }?.numberMessages ?? 0
    if numberMessages > 0 {
        let chatDirectoryURL = directoryURL.appendingPathComponent("chat_\(chatId)", isDirectory: true)
        createDirectory(url: chatDirectoryURL)

        // 📨 Obtener mensajes y contactos del chat
        let chatDump = try! api.getChat(
            chatId: chatId,
            directoryToSaveMedia: chatDirectoryURL)
        let messages = chatDump.messages
        let contactsInChat = chatDump.contacts

        // 💬 Guardar mensajes
        let messagesFilename = "chat_\(chatId)_messages.json"
        let messagesUrl = chatDirectoryURL.appendingPathComponent(messagesFilename, isDirectory: false)
        outputJSON(data: messages, to: messagesUrl)

        // 👥 Guardar info y contactos del chat
        if let chatInfo = chats.first(where: { $0.id == chatId }) {
            let chatInfoExtended = ChatInfoExtended(chat: chatInfo, contacts: contactsInChat)
            let chatInfoFilename = "chat_\(chatId)_info.json"
            let chatInfoUrl = chatDirectoryURL.appendingPathComponent(chatInfoFilename, isDirectory: false)
            outputJSON(data: chatInfoExtended, to: chatInfoUrl)
        }

    } else {
        print("No messages in chat \(chatId)")
    }
}

func outputJSON<T: Encodable>(data: T, to outputUrl: URL) {
    let jsonEncoder = JSONEncoder()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    jsonEncoder.dateEncodingStrategy = .formatted(formatter)
    jsonEncoder.outputFormatting = .prettyPrinted

    do {
        let jsonData = try jsonEncoder.encode(data)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            do {
                try jsonString.write(toFile: outputUrl.path, atomically: true, encoding: .utf8)
                print(">>> Saved file to \(outputUrl.path)")
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

func saveSingleChatMessages(for chatId: Int,
                              with directoryURL: URL,
                              from backupToUse: IPhoneBackup) {
    let chatDirectoryURL = directoryURL.appendingPathComponent("chat_\(chatId)", isDirectory: true)
    createDirectory(url: chatDirectoryURL)

    // Obtener mensajes, contactos y la información del chat indicado.
    let chatDump = try! api.getChat(chatId: chatId, directoryToSaveMedia: chatDirectoryURL)
    let messages = chatDump.messages
    let chatInfo = chatDump.chatInfo
    let contactsInChat = chatDump.contacts

    // Guardar mensajes
    if messages.count > 0 {
        let messagesFilename = "chat_\(chatId)_messages.json"
        let messagesUrl = chatDirectoryURL.appendingPathComponent(messagesFilename, isDirectory: false)
        outputJSON(data: messages, to: messagesUrl)
    } else {
        print("No messages in chat \(chatId)")
    }

    // Guardar la información del chat junto con sus contactos
    let chatInfoExtended = ChatInfoExtended(chat: chatInfo, contacts: contactsInChat)
    let chatInfoFilename = "chat_\(chatId)_info.json"
    let chatInfoUrl = chatDirectoryURL.appendingPathComponent(chatInfoFilename, isDirectory: false)
    outputJSON(data: chatInfoExtended, to: chatInfoUrl)
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

