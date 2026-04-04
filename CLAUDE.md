# ClipboardMarkdown

Native macOS menu bar utility die clipboardtekst opslaat als Markdown-bestand in ~/Downloads.

## Bouwen en installeren

```bash
xcodebuild -project ClipboardMarkdown.xcodeproj -scheme ClipboardMarkdown -configuration Debug build CONFIGURATION_BUILD_DIR=/tmp/ClipboardMarkdown_build
rm -rf /Applications/ClipboardMarkdown.app
cp -R /tmp/ClipboardMarkdown_build/ClipboardMarkdown.app /Applications/ClipboardMarkdown.app
```

## Technische details

- **Taal:** Swift 5, SwiftUI
- **Minimale macOS-versie:** 13.0
- **Menu bar:** `MenuBarExtra` met `.menu` style
- **Icoon in menubalk:** SF Symbol `doc.on.clipboard`
- **Bundle identifier:** `net.hoeijmakers.clipboardmarkdown`
- **Info.plist:** gegenereerd door Xcode (`GENERATE_INFOPLIST_FILE = YES`), `LSUIElement = YES` zodat de app niet in het Dock verschijnt

## Bestandsstructuur

- `ClipboardMarkdownApp.swift` — app entry point, definieert de `MenuBarExtra` scene
- `ContentView.swift` — de drie menu-items en het About-venster
- `ClipboardManager.swift` — clipboard lezen, bestand opslaan, naamconflicten oplossen, notificaties

## Gedrag

- Bestandsnaam: `yyyy-MM-dd HH.mm.ss.md`
- Bij naamconflict: suffix `(2)`, `(3)`, etc.
- Bevestiging via `UNUserNotificationCenter` (vraagt eenmalig toestemming)
- Foutmeldingen (leeg clipboard, Downloads niet bereikbaar) via dezelfde notificaties
