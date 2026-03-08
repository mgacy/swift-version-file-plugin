# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

VersionFilePlugin is a Swift Package Manager command plugin that maintains a `Version.swift` file containing semantic version numbers. It uses the bundled [semver shell utility](https://github.com/fsaintjacques/semver-tool) binary to bump versions according to semantic versioning rules (major/minor/patch/release/prerel).

## Development Commands

### Building
```bash
swift build
```

### Linting
```bash
mise run lint          # Run linting
mise run lint-fix      # Auto-fix linting issues
```

SwiftLint 0.62.2 is managed by mise. Configuration is in `.swiftlint.yml`.

### Testing the Plugin
```bash
# Create a version file
swift package --allow-writing-to-package-directory version-file --create 1.0.0

# Bump version (major | minor | patch | release | prerel)
swift package --allow-writing-to-package-directory version-file --bump patch

# Verbose output
swift package --allow-writing-to-package-directory version-file --verbose --bump minor
```

## Architecture

### Plugin Structure
The plugin is a SPM Command Plugin (`CommandPlugin`) in `Plugins/VersionFile/`:

- **VersionFile.swift** - Main plugin entry point implementing `CommandPlugin`. `performCommand()` processes arguments and dispatches to either `--bump <type>` or `--create <version>`. Target selection via `--target` option (defaults to all generic/executable targets, excludes test targets).
- **Extensions/String+Utils.swift** - Regex matching helper and `String: Error` conformance (allows throwing string literals directly as errors).
- **Extensions/PackagePlugin+Utils.swift** - Debug description for `PackagePlugin.Target`.

### Binary Dependency
The bundled `semver` tool lives in `Artifacts/semver.artifactbundle` and is defined as a binary target in `Package.swift`. It's invoked as a subprocess for version bumping.

### Code Flow
1. Plugin extracts command arguments (bump type or create version)
2. Identifies target source directories (`SourceModuleTarget` with `.generic` or `.executable` kind)
3. For bump: reads existing `Version.swift`, runs semver tool, writes new version
4. For create: writes new `Version.swift` with specified version
5. Generated file format: `enum Version { static let number = "x.y.z" }`

### CI/CD
The `.github/workflows/release.yml` workflow is manually triggered (`workflow_dispatch`) to create releases. It fetches the latest release tag, bumps the version using `mgacy/bump-version-action`, creates a git tag, and publishes a GitHub release.

## Code Style

### File Headers
Every file starts with a standard header comment block:
```swift
//
//  FileName.swift
//  VersionFilePlugin
//
//  Created by Author Name on MM/DD/YY.
//
```

### Conventions
- Use explicit types for public APIs
- Prefer guard statements for early returns
- Mark models as `Sendable` for Swift 6 concurrency
- Use `TypeName+Extension.swift` naming for extension files
- Use extensions to organize protocol conformances (with `// MARK: -` headers)
- Prefer computed properties over methods for simple getters
- Prefer typed throwing errors over generic `Error`
- Wrap long parameter lists across multiple lines, aligned vertically
- Document all public properties with `///` doc comments

### SwiftLint Thresholds
Key non-default SwiftLint settings:
- `line_length`: 200
- `function_body_length`: 50
- `file_length`: warning at 500, error at 1000
- `large_tuple`: warning at 6, error at 10
- `cyclomatic_complexity`: ignores case statements
- `identifier_name` excluded: `id`, `me`, `or`

### Documentation Style
```swift
/// Returns the current version number from the version file at the given path.
///
/// - Parameter path: The path to the version file.
/// - Returns: The current version number.
func currentVersion(path: Path) throws -> String {
```

## Requirements

- Swift 5.6+ (specified in Package.swift)
- Uses PackagePlugin framework
- Requires `--allow-writing-to-package-directory` permission flag
