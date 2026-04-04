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
- Klikken op notificatie opent het bestand in de standaard-app
- Foutmeldingen (leeg clipboard, Downloads niet bereikbaar) via dezelfde notificaties

## Clipboard-prioriteit

1. **HTML met structuur** (headings, code, lijsten, links) → `HTMLToMarkdown`
2. **RTF** (Pages, Word, etc.) → `RTFToMarkdown`
3. **Plain text** → direct opslaan

Bronnen zonder structuur (LinkedIn, plain prose in divs) vallen automatisch terug op plain text.

## Bekende eigenaardigheden per bron

- **Google Docs**: wikkelt `<li>` in `<p>` → gefixed door `<p>` inside `<li>` te strippen
- **Pages RTF**: bullet-marker en tekst zijn aparte paragrafen → gefixed met post-processing regex
- **LinkedIn**: gebruikt `\*` als interne opmaakmarkers en `<div>` voor alinea's → valt terug op plain text (geen HTML-structuur)
