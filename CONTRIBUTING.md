# Contributing

Thank you for your interest in GitConfigs.

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Harassment or abusive behavior in issues, discussions, or pull requests is not acceptable.

## Environment

**Building and running the GUI requires macOS** (SwiftUI + AppKit). **Unit tests** also assume a macOS Swift toolchain and `/usr/bin/git`.

### Linux, Windows, and Docker

This app **cannot** be built or run inside **Linux Docker** (or on Linux/Windows hosts without a macOS environment) because it depends on **Apple-only frameworks**. We do not support a containerized workflow for the GUI.

If you do not have a Mac, you can still:

- Improve **documentation** (README, CONTRIBUTING, issue templates).
- File **issues** with reproduction steps for others to verify.
- Prepare changes and ask a maintainer or friend with a Mac to run `make test` / `make test-ui`.

## Getting started (macOS)

1. Clone the repository.
2. Open a terminal in the repo root.
3. Build and test:

   ```bash
   make build
   make test
   ```

4. Optional UI tests (needs Xcode + XcodeGen, GUI session):

   ```bash
   brew install xcodegen   # if needed
   make test-ui
   ```

## Xcode project and UI tests

UI tests live in [`UITests/`](UITests/) and are driven by Xcode, not SPM.

- Project definition: [`project.yml`](project.yml) (XcodeGen).
- After editing `project.yml`, run:

  ```bash
  xcodegen generate
  ```

- Generated output: **`GitConfigsUI.xcodeproj`**. If it is out of date, `make test-ui` still runs `xcodegen generate` first.

## Pull requests

- Describe **what** changed and **why** (short is fine).
- For **UI changes**, include **before/after screenshots** when helpful.
- Run **`make test`** before opening a PR. Run **`make test-ui`** when you touch UI or test targets, if you can.
- Follow existing **Swift style** in the repo (naming, structure). Avoid unrelated refactors in the same PR.

## Commits and branches

External contributors: clear, focused commits and descriptive messages are enough. Maintainers may use stricter internal conventions; that does not block community PRs.

## Dependency lockfile

`Package.resolved` is committed for **reproducible** dependency resolution. After changing `Package.swift` dependencies, run `swift package resolve` and include the updated lockfile when appropriate.

## Questions

Open an issue in **this repository** on GitHub for bugs or feature ideas. For security-sensitive topics, see [SECURITY.md](SECURITY.md).
