# AGENTS.md

## Project Overview

This repository contains `WABackupExtractor`, a macOS command-line tool written in
Swift. It reads local iPhone backups and exports WhatsApp chats, messages,
contacts, profile photos, and media files using the `SwiftWABackupAPI`
dependency.

## Tech Stack

- Swift Package Manager
- Swift 5.8+
- macOS command-line executable

## Repository Layout

- `Package.swift`: package definition and dependency on `SwiftWABackupAPI`
- `Sources/main.swift`: the full application entry point and CLI workflow
- `README.md`: installation, usage, and output format documentation
- `WABackup/`: generated extractor output already present in the repository

## Working Notes

- The executable target is `WABackupExtractor`.
- Most behavior lives in `Sources/main.swift`; there are no internal modules yet.
- The tool depends on access to iPhone backups under
  `~/Library/Application Support/MobileSync/Backup/`.
- The app may prompt the user to choose a backup when more than one valid backup
  exists.

## Common Commands

Build the project:

```bash
swift build
```

Build a release binary:

```bash
swift build -c release
```

Run the extractor:

```bash
swift run WABackupExtractor --help
```

Note: the current CLI does not implement a dedicated `--help` flag, so invalid
arguments are what trigger the usage text.

## Change Guidelines

- Keep the command-line interface simple and consistent with the README.
- If you add or rename flags, update `README.md` in the same change.
- Preserve the current output folder conventions unless the change explicitly
  intends to alter them.
- Treat `WABackup/` as generated data. Review changes there carefully before
  committing.
- Be mindful that this project handles private chat data. Avoid introducing
  logging or sample data that would expose personal information.

## Validation

- Minimum validation: run `swift build`.
- For behavior changes, also sanity-check the CLI flow and generated file names.

