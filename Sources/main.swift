//
//  main.swift
//
//
//  Created by Domingo Gallardo on 24/05/23.
//

import SwiftWABackupAPI

let api = WABackup()

print ("Has local backups: \(api.hasLocalBackup())")
if let getLocalBackups = api.getLocalBackups() {
    for backup in getLocalBackups {
        print("Backup path: \(backup.path)")
        api.connectChatStorage(backupPath: backup.path)
    }
} else {
    print("No local backups")
}
