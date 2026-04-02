# WABackupExtractor

`WABackupExtractor` is a macOS command-line application, written in Swift, which allows 
you to backup and explore your WhatsApp chats. The application leverages the 
[`SwiftWABackupAPI`](https://github.com/domingogallardo/SwiftWABackupAPI), which we 
also developed and maintain.

The application can access iPhone backups located in 
`~/Library/Application Support/MobileSync/Backup/` and extract both chat messages and chat metadata.

## ⛔️Privacy Warning⛔️

This tool is designed to access WhatsApp backup data for legitimate purposes such as data backup and 
recovery or data analysis. It is crucial to remember that accessing, extracting, or analyzing chat data 
without the explicit consent of all involved parties can violate privacy laws and regulations, as well 
as WhatsApp's terms of service. 

Any use of this tool should respect privacy laws and regulations, as well as WhatsApp's terms of service. 

Always respect the privacy and rights of others.☮️

## Prerequisites

The Swift language toolkit must be installed on your Mac. You can install it by installing 
Xcode or the _Xcode Command Line Tools_ using the following command:


```bash
xcode-select --install
```

Once installed, you'll be able to run the Swift compiler from the terminal.

Also, ensure you've granted the application permission to access the iPhone backup files.
You can do this by going to `System Preferences -> Security & Privacy -> Full Disk Access`
and adding the `Terminal` application.


## Installation

To begin, clone the repository from GitHub:

```bash
git clone https://github.com/domingogallardo/WABackupExtractor.git
```

Next, build and install the application using the Swift build system:

```bash
cd WABackupExtractor
swift build -c release
sudo cp .build/release/WABackupExtractor /usr/local/bin/WABackupExtractor
```

## Usage

To use the application, first create an _unencrypted_ backup of your iPhone on 
your Mac. This can be done by connecting your iPhone to the Mac, selecting it in the 
Finder, and making a backup.

After installing the application, you can use it as follows:

```bash
WABackupExtractor [-c <chat_id>] [-o <output_directory>] [-all]
```

By default, the application creates a `WABackup` directory. Inside it, a `Chats/` subdirectory is created, 
where it saves a `chats.json` file containing all chat metadata and the corresponding profile pictures 
of each chat as separate `.jpg` or `.thumb` files.

Upon launching the application, if more than one backup is available, the user will be presented with a list of backups to choose from. If only one backup is available, it will be selected automatically.

Within the `chats.json` file, you will find all the chat IDs. You can extract all messages from a 
specific chat using the `-c <chat_id>` flag. This will create a `chat_<id>` folder containing a
`chat_<id>_messages.json` file with the messages, all associated media files, and the information 
and the contacts for that chat (in `chat_<id>_info.json`). Contacts’ profile images are saved in 
the same folder if available.

Message JSON files follow the `SwiftWABackupAPI` public contract. Message identity is exported
through the structured `author` object instead of the old top-level `senderName` and `senderPhone`
fields.

The extractor does not reinterpret these fields on its own; it serializes them exactly as produced
by `SwiftWABackupAPI`.

The output directory can be customized using the `-o <output_directory>` flag. It 
can either be an absolute path (starting with a slash) or a relative path to the current directory.

The flag `-all` saves all the chats.

## Example Usage

For instance, if you want to extract all chat info from the most recent backup and save them 
to a directory called `mychats`, you can run:

```bash
WABackupExtractor -o mychats
```

This command will create a mychats/Chats/chats.json file, along with image files like 
`chat_3.jpg` for each chat with a profile picture.

To extract all messages and contacts from the chat with ID  `226`, you can run:

```bash
WABackupExtractor -c 226
```

Since no output directory is specified in this command, the application will create the default 
`WABackup` directory. Inside this directory, it will create a `chat_226` folder containing the 
`chat_226_messages.json` and `chat_226_info.json` files, along with all media files associated with the chat 
and the contacts’ profile images.

## Output Structure

When extracting data, the application creates the following directory structure:

```
WABackup/
├── Chats/
│   ├── chats.json
│   ├── chat_1.jpg
│   ├── chat_2.jpg
│   └── …
├── chat_1/
│   ├── chat_1_messages.json
│   └── chat_1_info.json
├── chat_2/
│   └── …
```

- `Chats/chats.json`: metadata of all available chats.
- `Chats/chat_<id>.jpg`: profile image for each chat (group or individual).
- `chat_<id>/`: folder with messages and contacts for that specific chat.

### Example `chat_<id>_info.json` file

This file contains both the metadata of the chat and the list of participants (with their profile photo filenames if available):

```json
{
  "contacts": [
    {
      "name": "Me",
      "phone": "34987654321",
      "photoFilename": "34987654321.jpg"
    },
    {
      "name": "Laura Pérez",
      "phone": "34611112222",
      "photoFilename": "34611112222.jpg"
    }
  ],
  "chat": {
    "id": 3,
    "name": "Laura Pérez",
    "contactJid": "34611112222@s.whatsapp.net",
    "chatType": "individual",
    "numberMessages": 3051,
    "lastMessageDate": "2025-03-07T15:11:45Z",
    "isArchived": false
  }
}
```

### Example `chat_<id>_messages.json` excerpt

Normal authored messages use `author`:

```json
[
  {
    "author": {
      "displayName": "Laura Pérez",
      "jid": "34611112222@s.whatsapp.net",
      "kind": "participant",
      "phone": "34611112222",
      "source": "chatSession"
    },
    "chatId": 3,
    "date": "2025-03-07T15:12:01Z",
    "id": 98124,
    "isFromMe": false,
    "message": "Vale, te lo llevo mañana.",
    "messageType": "Text"
  }
]
```

Notes:

- Top-level `senderName` and `senderPhone` are no longer exported.
- Use `author` for sender identity when it is available.
- Do not assume every message has a real phone-bearing author.
- Dates are serialized as ISO 8601 timestamps with timezone information.

## Support

Comments and suggestions are welcome. Feel free to add them in the [_Discussions_](https://github.com/domingogallardo/WABackupExtractor/discussions) section.

Enjoy using WABackupExtractor!🎉🚀💻
