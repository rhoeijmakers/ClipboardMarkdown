# ClipboardMarkdown

A minimal macOS menu bar app that saves clipboard content as a `.md` file in `~/Downloads`.

Handles plain text, rich text (RTF from Pages, Word, etc.), and structured HTML (Google Docs, web pages) — converting each to clean Markdown.

## Requirements

- macOS 13.0 or later
- Xcode 15 or later

## Build and run

1. Open `ClipboardMarkdown.xcodeproj` in Xcode
2. Select the **ClipboardMarkdown** scheme with **My Mac** as the destination
3. Press **⌘R** to build and run

The app does not appear in the Dock — only as a clipboard icon in the menu bar.

Or build from the command line:

```bash
xcodebuild -project ClipboardMarkdown.xcodeproj -scheme ClipboardMarkdown -configuration Debug build CONFIGURATION_BUILD_DIR=/tmp/ClipboardMarkdown_build
cp -R /tmp/ClipboardMarkdown_build/ClipboardMarkdown.app /Applications/ClipboardMarkdown.app
```

## Usage

Click the clipboard icon in the menu bar:

| Menu item | Action |
|---|---|
| Save Clipboard as Markdown | Saves clipboard content as `.md` in `~/Downloads` |
| Open Downloads Folder | Opens the Downloads folder in Finder |
| Quit | Quits the app |

**Keyboard shortcut:** ⌘⇧S

**File name format:** `2026-04-04 15.42.10.md`
On conflict, a suffix is added automatically: `2026-04-04 15.42.10 (2).md`

On first use, macOS will ask for notification permission. The app sends a system notification confirming each successful save, or reporting an error.

## How clipboard content is converted

The app picks the best available format from the clipboard in this order:

1. **HTML with structure** (headings, code blocks, lists, links) → converted via `HTMLToMarkdown`
2. **RTF** (Pages, Word, etc.) → converted via `RTFToMarkdown`
3. **Plain text** → saved as-is

Content without meaningful structure (e.g. LinkedIn posts, plain prose in `<div>` tags) automatically falls back to plain text.

PDF is not supported — it's a rendering format, not a copy format. The clipboard never carries the document, only whatever text the PDF viewer chose to expose.

## Code signing

No Apple Developer account is required for local use. Xcode uses automatic signing by default. If macOS blocks the app when launching outside Xcode, run:

```bash
xattr -dr com.apple.quarantine /path/to/ClipboardMarkdown.app
```

## Project structure

```
ClipboardMarkdown/
├── ClipboardMarkdown.xcodeproj/
│   └── project.pbxproj
└── ClipboardMarkdown/
    ├── ClipboardMarkdownApp.swift   # App entry point, MenuBarExtra scene
    ├── ContentView.swift            # Menu items
    ├── ClipboardManager.swift       # Clipboard reading, file saving, notifications
    ├── HTMLToMarkdown.swift         # HTML → Markdown conversion
    └── RTFToMarkdown.swift          # RTF → Markdown conversion
```

## License

MIT — see [LICENSE](LICENSE).
