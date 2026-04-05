# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
make build          # debug build
make build-release  # release build (optimized)
make run            # run via swift run (terminal keeps keyboard focus)
make open           # build + open as .app (correct keyboard focus)
make icon           # SVG → AppIcon.icns  (requires: brew install librsvg)
make bundle         # release build + .app bundle with icon
make install        # bundle + copy to /Applications
make uninstall      # remove from /Applications
make clean          # clean build artifacts, bundle, generated icons
make test           # unit + BDD tests (swift test)
make test-ui        # XCUITest via xcodebuild (requires Xcode; see Testing)
make test-all       # make test && make test-ui
```

## Testing

- **`make test`** — Swift Package tests: XCTest (`ProfileTests`, `ConfigScopeTests`, `GitConfigServiceTests` with isolated `HOME`), plus Quick/Nimble BDD specs (`Tests/GitConfigsTests/BDD/`). Requires `/usr/bin/git`.
- **`make test-ui`** — Runs **XcodeGen** (`brew install xcodegen`) to generate `GitConfigsUI.xcodeproj` from [`project.yml`](project.yml), then runs `xcodebuild test` for the `GitConfigsApp` scheme. XCUITest needs a normal **logged-in macOS GUI session** (automation mode); headless/SSH-only environments often time out.
- Regenerate the Xcode project after editing `project.yml`: `xcodegen generate`.

## Architecture

Swift Package Manager project with a thin executable and shared library. macOS 13+ target. [`GitConfigsUI.xcodeproj`](GitConfigsUI.xcodeproj) (generated from [`project.yml`](project.yml) via XcodeGen) hosts **XCUITest** (SPM does not run UI test bundles).

**Targets:**

- **`GitConfigsLib`** — [`Sources/GitConfigsLib/`](Sources/GitConfigsLib/) — models, `GitConfigService`, SwiftUI views. `ContentView` is `public` for the app target.
- **`GitConfigs`** — [`Sources/GitConfigs/App.swift`](Sources/GitConfigs/App.swift) — `@main` entry point.
- **`GitConfigsTests`** — [`Tests/GitConfigsTests/`](Tests/GitConfigsTests/) — XCTest + Quick/Nimble.

**Data flow:**

```
~/.gitconfig  ←→  GitConfigService  ←→  ContentView  →  ProfileRow / ProfileEditor
```

**Key design decisions:**

- **Persistence is `~/.gitconfig` only.** Profiles are stored as custom keys under the namespace `gituserchange-profile.<UUID>.{label,name,email}` using `git config --global`. There is no separate database or file.

- **Activating a profile** simply writes `user.name` and `user.email` to `~/.gitconfig` globally. The "active" profile is detected by comparing the current global git name/email against each profile's name/email — there is no separate "active" flag stored.

- **`GitConfigService`** is a singleton (`shared`) that shells out to `/usr/bin/git` for all reads and writes. It never caches — every `reload()` call re-reads from git config.

- **`ContentView`** owns all state (`profiles`, `currentName`, `currentEmail`, `showEditor`). Child views receive data and callbacks; they hold no app state of their own.

- **`ProfileEditor`** is presented as a `.sheet`. It takes an optional `Profile?` (nil = new profile). On save it calls back into `ContentView` which calls the service and reloads.

- **Keyboard focus:** `NSApp.activate(ignoringOtherApps: true)` is called on app launch (App.swift) and whenever the editor sheet opens (ContentView `onChange`). This is needed because `swift run` keeps keyboard focus in the terminal.

## Assets

`Assets/icon.svg` is the source for the app icon. Run `make icon` to compile it to `Assets/AppIcon.icns`, which `make bundle` then includes in `Contents/Resources/`.
