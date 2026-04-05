# GitConfigs

macOS menu-bar-friendly utility to manage **Git user profiles** (`user.name` / `user.email`) and related global Git settings. Profiles and settings are stored in your **`~/.gitconfig`** via `/usr/bin/git` — there is no separate database or network sync.

<!-- Optional: add screenshots (e.g. `docs/screenshots/main.png`) and reference them here. -->

## Requirements

- **macOS 13+**
- **Swift** toolchain (Xcode or standalone)
- **`/usr/bin/git`** on PATH for runtime operations
- **Xcode** + **XcodeGen** (`brew install xcodegen`) for **UI tests** (`make test-ui`)
- **`rsvg-convert`** (`brew install librsvg`) only if you run `make icon` **without** [`Assets/logo-source.png`](Assets/logo-source.png) (then the icon is built from [`Assets/icon.svg`](Assets/icon.svg))
- **`magick`** (`brew install imagemagick`) only if you use **`make import-logo`** to turn a non-square [`logo.png`](logo.png) in the repo root into a square [`Assets/logo-source.png`](Assets/logo-source.png)

### Non-macOS contributors

The UI is built with **SwiftUI** and **AppKit**. You **cannot** build or run this application on Linux or Windows, including inside **Linux Docker** images — those platforms do not provide the Apple frameworks this app needs.

You can still help with **documentation**, **issue triage**, or **code** if you have access to a Mac (local or remote) to validate changes. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Quick start

```bash
make build       # debug build (Swift Package Manager)
make run         # run via swift run (terminal may keep keyboard focus)
make open        # build + open the debug app (better keyboard focus)
make test        # unit + BDD tests (isolated test HOME; needs git)
```

Release bundle and install:

```bash
make import-logo # optional: logo.png → square Assets/logo-source.png (1024², center crop)
make icon        # logo PNG (preferred) or SVG → AppIcon.icns + Xcode AppIcon + in-app logo asset
make bundle      # release .app in the repo root
make install     # copy bundle to /Applications
```

## UI tests

```bash
make test-ui
```

`make test-ui` regenerates **`GitConfigsUI.xcodeproj`** from [`project.yml`](project.yml) with XcodeGen, then runs **XCUITest**. Use a normal **logged-in macOS GUI session**; headless or SSH-only sessions often time out.

```bash
make test-all    # swift test + UI tests
```

## Xcode project

The Swift package is the source of truth for the library and CLI. The **Xcode project** exists only for **XCUITest**:

- Spec: [`project.yml`](project.yml) (XcodeGen)
- Generated project: **`GitConfigsUI.xcodeproj`** (tracked in git for clone-and-test; regenerate with `xcodegen generate` after editing `project.yml`)

## Architecture

- **`GitConfigsLib`** — models, `GitConfigService`, SwiftUI views ([`Sources/GitConfigsLib/`](Sources/GitConfigsLib/))
- **`GitConfigs`** — thin `@main` executable ([`Sources/GitConfigs/`](Sources/GitConfigs/))
- **`GitConfigsTests`** — XCTest + Quick/Nimble ([`Tests/GitConfigsTests/`](Tests/GitConfigsTests/))

`GitConfigService` shells out to **`/usr/bin/git`** for all reads/writes and does not cache; `reload()` re-reads from git config.

## Privacy / data

The app only touches your local **`~/.gitconfig`** through Git. It does not intentionally collect analytics or send data over the network.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). This project uses the [Contributor Covenant](CODE_OF_CONDUCT.md); please be respectful in issues and pull requests.

## Security

See [SECURITY.md](SECURITY.md) for how to report vulnerabilities.

## License

[MIT](LICENSE)

## Developer notes (AI / tooling)

See [CLAUDE.md](CLAUDE.md) for command reference and design notes aimed at assistants and maintainers.
