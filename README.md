# WABackupViewer

`WABackupViewer` is a macOS command-line application, written in Swift, which allows 
you to backup and explore your WhatsApp chats. The application leverages the 
[`SwiftWABackupAPI`](https://github.com/domingogallardo/SwiftWABackupAPI), which we 
also developed and maintain.

The application can access iPhone backups located in 
`~/Library/Application Support/MobileSync/Backup/` and extract both chat messages and chat metadata.

## Prerequisites

The Swift language toolkit must be installed on your Mac. You can install it by installing 
Xcode or the _Xcode Command Line Tools_ using the following command:


```bash
xcode-select --install
```

Once installed, you'll be able to run the Swift compiler from the terminal.

Also, ensure you've granted the application permission to access the iPhone backup files.
You can do this by going to `System Preferences -> Security & Privacy -> Full Disk Access`
and adding the Terminal application.


## Installation

To begin, clone the repository from GitHub:

```bash
git clone https://github.com/domingogallardo/WABackupViewer.git
```

Next, build and install the application using the Swift build system:

```bash
cd WABackupViewer
swift build -c release
sudo cp .build/release/WABackupViewer /usr/local/bin/WABackupViewer
```

## Usage

To use the application, first create an _unencrypted_ backup of your iPhone on 
your Mac. This can be done by connecting your iPhone to the Mac, selecting it in the 
Finder, and making a backup.

After installing the application, you can use it as follows:

```bash
WABackupViewer [-b <backup_id>] [-c <chat_id>] [-o <output_directory>] [-all]
```

By default, the application creates a `WABackup` directory, where it saves a 
`chats.json` file containing all chat information from the most recent WhatsApp backup. 
The application prints all backup identifiers, allowing you to select a different 
backup using the `-b <backup_id>` flag.

Within the `chats.json` file, you will find all the chat IDs. You can extract all the messages 
from a specific chat using the `-c <chat_id>` flag. This will create a `chat_<id>` folder, 
where a `chat_<id>.json` file will be saved, along with all the associated media files.

The output directory can be customized using the `-o <output_directory>` flag. It 
can either be an absolute path (starting with a slash) or a relative path to the current directory.

The flag `-all` saves all the chats.

## Example Usage

For instance, if you want to extract all chat info from the most recent backup and save them 
to a directory called `mychats`, you can run:

```bash
WABackupViewer -o mychats
```

This command will create a `mychats/chats.json` file.  By viewing this file, 
you can identify the chat whose messages you wish to extract.

For example, to extract all messages from the chat with ID  `226` from a specific 
backup with ID `abcd1234`, you can run:

```bash
WABackupViewer -b abcd1234 -c 226
```

Since no output directory is specified in this command, the application will create 
the default `WABackup` directory. Inside this directory, it will create a `chat_226` folder containing 
the `chat_226.json` file and all media files associated with this chat.

## ⛔️Privacy Warning⛔️

This tool is designed to access WhatsApp backup data for legitimate purposes such as data backup and 
recovery or data analysis. It is crucial to remember that accessing, extracting, or analyzing chat data 
without the explicit consent of all involved parties can violate privacy laws and regulations, as well 
as WhatsApp's terms of service. 

Any use of this tool should respect privacy laws and regulations, as well as WhatsApp's terms of service. 

Always respect the privacy and rights of others. ☮️

## Support

Comments and suggestions are welcome. Feel free to add them in the [_Discussions_](https://github.com/domingogallardo/WABackupViewer/discussions) section.

Enjoy using WABackupViewer!🎉🚀💻
