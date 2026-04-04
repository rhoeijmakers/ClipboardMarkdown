# ClipboardMarkdown

Minimalistische macOS menu bar app die platte tekst van het klembord opslaat als `.md`-bestand in `~/Downloads`.

## Vereisten

- macOS 13.0 of nieuwer
- Xcode 15 of nieuwer

## Builden en starten

1. Open `ClipboardMarkdown.xcodeproj` in Xcode
2. Selecteer het schema **ClipboardMarkdown** en als destination **My Mac**
3. Druk op **⌘R** om te builden en starten

De app verschijnt niet in het Dock — alleen als klembord-icoon in de menubalk.

## Gebruik

Klik op het klembord-icoon in de menubalk:

| Menu-item | Actie |
|---|---|
| Save Clipboard as Markdown | Slaat klembordtekst op als `.md` in `~/Downloads` |
| Open Downloads Folder | Opent de Downloads-map in Finder |
| Quit | Sluit de app |

**Bestandsnaamformaat:** `2026-04-04 15.42.10.md`
Bij een naamconflict wordt automatisch een suffix toegevoegd: `2026-04-04 15.42.10 (2).md`

Bij het eerste gebruik vraagt macOS toestemming voor meldingen. De app stuurt een systeemmelding ter bevestiging van elke succesvolle opslag, of bij een fout.

## Code signing (lokaal gebruik)

Voor lokaal gebruik is geen Apple Developer-account nodig. Xcode kiest automatisch **Automatic** signing. Als je de app buiten Xcode wil draaien (door te dubbelklikken), zal macOS bij de eerste keer vragen om je akkoord — dat is normaal voor niet-gesigneerde of lokaal gesigneerde apps.

Als je Gatekeeper wil omzeilen na het builden:

```bash
xattr -dr com.apple.quarantine /pad/naar/ClipboardMarkdown.app
```

## Structuur

```
ClipboardMarkdown/
├── ClipboardMarkdown.xcodeproj/
│   └── project.pbxproj
├── ClipboardMarkdown/
│   ├── ClipboardMarkdownApp.swift   # App entry point, MenuBarExtra scene
│   ├── ContentView.swift            # Menu-items
│   └── ClipboardManager.swift      # Klembord lezen, bestand opslaan, meldingen
└── README.md
```

## Uitbreidingsmogelijkheden (v2+)

- Eerste regel als bestandsnaam gebruiken
- Popup voor handmatige titel
- Standaardmap instelbaar via Preferences
- Bron-URL mee opslaan
- Frontmatter toevoegen
- HTML/rich text naar Markdown converteren
- Globale sneltoets registreren via `NSEvent.addGlobalMonitorForEvents`
- Keuze tussen direct opslaan of Save-dialoog
