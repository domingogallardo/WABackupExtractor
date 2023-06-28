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
your Mac. Simply connect the iPhone to the Mac, select it in the Finder and make a backup.

After the application is installed, you can use it as follows:

```bash
WABackupViewer [-b <backup_id>] [-c <chat_id>] [-o <output_directory>] [-all]
```

By default, the application will create a `WABackup` directory and save the file `chats.json`, 
containing all the chat info from the most recent WhatsApp backup, within it. The application 
will also print all backup identifiers, and you can select a different backup 
using the `-b <backup_id>` flag.

Within the `chats.json` file, you will find all the chat IDs. You can extract all the messages 
from a specific chat using the `-c <chat_id>` flag. The file `chat_<id>.json` will 
then be saved in the output directory.

The output directory can be customized using the `-o <output_directory>` flag. It 
can either be an absolute path, starting with a slash, or a relative path to the current directory.

The flag `-all` saves all the chats.

## Example Usage

For instance, if you want to extract all chat info from the most recent backup and save them 
to a directory called `mychats`, you would run:

```bash
WABackupViewer -o mychats
```

The `mychats/chats.json` file will be created. You can then view this file to identify 
the chat for which you want to extract messages.

As another example, to extract all messages from chat with ID `226` from a specific 
backup with ID `abcd1234`, you would run:

```bash
WABackupViewer -b abcd1234 -c 226
```

As no output directory is specified, the default `WABackup` directory will be created, 
and the messages will be stored as a JSON file `WABackup/chat_226.json`.


## Support

**Please note that both the application and the underlying library are in the early stages 
of development.** 🚧⚙️👩‍💻👨‍💻

Comments and suggestions are welcome. Feel free to add them in the [_Discussions_](https://github.com/domingogallardo/WABackupViewer/discussions) section.

Enjoy using WABackupViewer!🎉🚀💻