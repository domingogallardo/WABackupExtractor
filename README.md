# WABackupViewer

WABackupViewer is a Swift command-line MacOS application that allows you to backup your WhatsApp messages. The application uses the [`SwiftWABackupAPI`](https://github.com/domingogallardo/SwiftWABackupAPI), which is also developed and maintained by us.

The application can access iPhone backups in the `~/Library/Application Support/MobileSync/Backup/` directory and extract chat messages or chat metadata.

## Prerequisites

You need the Swift language toolkit installed in your Mac. You can install Xcode or the 
_Xcode Command Line Tools_ with the command:

```bash
xcode-select --install
```

Once installed we can run Swift compiler from the terminal.

Also, make sure you've given the application permission to access the iPhone backup files. 
You can do this by going to `System Preferences -> Security & Privacy -> Full Disk Access` 
and grant the permission to the `Terminal` application.

## Installation

Firstly, clone the repository from GitHub:

```bash
git clone https://github.com/domingogallardo/WABackupViewer.git
```

Build and install the application using Swift build system:

```bash
cd WABackupViewer
swift build -c release
sudo cp .build/release/WABackupViewer /usr/local/bin/WABackupViewer
```

## Usage

The basic usage of the application is as follows:

```bash
WABackupViewer [-b <backup_id>] [-c <chat_id>] [-o <output_filename>]
```

Where:

- `-b <backup_id>`: specify the backup ID you want to extract the messages from. If more than 
   one backup exists and no backup ID is provided, the application will list all the backups
   identifiers and their dates and automatically choose the most recent backup.
- `-c <chat_id>`: specify the chat ID from which you want to extract the messages.
- `-o <output_filename>`: specify the output filename for the JSON file with the chats information 
   or messages. If no filename is provided, the default filename will be `chats.json` for the chats 
   information or `chat_<id>.json` for the messages information.

## Example Usage

For example, if you want to extract all chats info from the most recent backup and save them to `mychats.json`, you would run:

```bash
WABackupViewer -o mychats.json
```

You can read the file to find the identifier of the chat that you want to extract the messages. 

Another example, if you want to extract all messages from chat with ID `226` from a specific backup 
with ID `abcd1234`, you would run:

```bash
WABackupViewer -b abcd1234 -c 226
```

The messages will be in JSON format in the file `chat_226.json`.

**Please notice that the application and the library are in very early development stage**

Enjoy using WABackupViewer!