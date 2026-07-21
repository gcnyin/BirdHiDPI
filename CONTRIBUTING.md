# Contributing to Bird HiDPI

Thanks for helping improve Bird HiDPI. Display-mode code can affect the active macOS session, so changes should stay small, reviewable, and explicit about hardware testing.

## Before Opening An Issue

- Search existing issues for the same display, macOS version, and symptom.
- Confirm that the requested mode appears after refreshing the app.
- Save ongoing work before reproducing a mode-switch problem.
- Do not post serial numbers, full EDID dumps, crash reports, or system profiles without removing personal information.

Bug reports should include:

- macOS version and build number
- Mac model and chip
- display manufacturer and model
- connection path, including docks or adapters
- selected logical resolution, framebuffer size, and refresh rate
- whether Restore, logging out, or reconnecting the display recovered the session
- exact steps and the complete error shown by the app

## Development Setup

Requirements:

- macOS 13 or later
- Xcode Command Line Tools
- an external display only for optional hardware integration tests

```sh
make build
make test
make app
```

`make test` validates both localization catalogs and runs the unit test suite. Tests that inspect or change a live display are disabled unless explicitly requested through environment variables.

## Pull Requests

- Keep changes focused and avoid unrelated formatting or refactoring.
- Add or update tests when mode filtering, matching, verification, persistence, or localization behavior changes.
- Update both `README.md` and `README.en.md` when public behavior or requirements change.
- Keep English and Simplified Chinese localization keys in sync.
- Run `make test` and `make release` before requesting review.
- Describe the macOS version and display hardware used for any live mode-switch verification.

Do not add display overrides, EDID modifications, virtual displays, capture streams, privileged helpers, or administrator requirements without prior discussion. Those approaches materially change the project's safety and architecture.

## Hardware Tests

The integration test changes the current external-display mode. It is never required for a documentation-only change and is not run by CI.

```sh
RUN_DISPLAY_INTEGRATION_TEST=1 \
swift test --filter DisplayIntegrationTests/testResolutionAndHiDPIToggleEndToEnd
```

Before running it, save your work and verify that logging out or reconnecting the display is available as a recovery path. Include the original and final mode in the pull request description.

## Commit Messages

Use short imperative subjects. Conventional prefixes such as `feat:`, `fix:`, `docs:`, `test:`, and `chore:` are welcome but not required.

## Private API Changes

Every newly referenced private symbol must be loaded dynamically and guarded when unavailable. Document the macOS versions and hardware used to validate its behavior, and preserve a recovery path when a switch fails.
