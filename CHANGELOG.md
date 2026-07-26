# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The project does not yet declare a compatibility policy because it depends on private macOS APIs.

## [Unreleased]

## [1.0.3] - 2026-07-26

### Changed

- Compacted the main UI and moved per-display apply actions into each display's header.

## [1.0.2] - 2026-07-22

### Changed

- The external display list now refreshes whenever the menu bar window opens, so the UI reflects the current connection state.
- Removed the redundant manual display refresh button.

## [1.0.1] - 2026-07-21

### Added

- Traditional Chinese, French, German, Italian, Spanish, Portuguese, Swedish, Norwegian Bokmål, and Irish localizations.

### Changed

- Language choices now use their native names and are sorted by BCP 47 language tag, with the system-language option first.
- English is now the primary README, with Simplified Chinese available as a supplementary translation.

## [1.0.0] - 2026-07-21

### Added

- Native SwiftUI menu bar interface for external-display mode selection.
- Separate Standard and HiDPI resolution lists from the complete WindowServer mode table.
- Direct mode-number switching on the original physical display.
- Post-switch verification of framebuffer, online display set, and arrangement.
- Automatic restoration when verification fails, Restore is clicked, or the app exits normally.
- English, Simplified Chinese, and automatic system-language selection.
- Launch-at-login support.
- Custom macOS application icon with reproducible CoreGraphics source.
- Release archive generation with SHA-256 checksums.
- MIT License.

### Changed

- Public project, application, and release artifact names are now `Bird HiDPI`.

### Security

- No privileged helper, administrator permission, Screen Recording permission, display override, EDID modification, virtual display, or network telemetry.

### Known Limitations

- Uses private SkyLight APIs and is not eligible for Mac App Store distribution.
- Available modes depend on the macOS version, GPU, connection, and display.
- Public builds are currently ad-hoc signed and not notarized.
