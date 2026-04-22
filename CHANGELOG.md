# Changelog

## [1.1] — 2026-04-22

### Fixed
- HTML from Claude (and other sources with only bold/italic) now converts correctly instead of falling back to plain text — `<strong>` and `<em>` are now recognised as structural HTML indicators.
- Bold formatting is no longer stripped during HTML conversion — the cleanup regex was matching `**text**` and replacing the markers with nothing; it now only removes sequences of 4+ consecutive asterisks (truly empty markers).
