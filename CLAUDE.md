# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

VersionFilePlugin is a Swift Package Manager command plugin that maintains a `Version.swift` file containing semantic version numbers. The plugin uses the bundled semver binary to bump versions according to semantic versioning rules (major/minor/patch/release/prerel).

## Development Commands

### Building
```bash
swift build
```

### Linting
```bash
# Run linting
mise run lint

# Auto-fix linting issues
mise run lint-fix
```

The project uses SwiftLint 0.62.2 managed by mise. Configuration is in `.swiftlint.yml` with specific opt-in rules and customizations.

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
The plugin is implemented as a SPM Command Plugin (`CommandPlugin`) with three main components:

1. **VersionFile.swift** (`Plugins/VersionFile/VersionFile.swift`) - Main plugin entry point implementing `CommandPlugin` protocol
   - `performCommand()` - Entry point that processes arguments and executes commands
   - Supports two commands: `--bump <type>` and `--create <version>`
   - Target selection via `--target` option (defaults to all generic/executable targets, excludes test targets)

2. **Extension Utilities**:
   - `String+Utils.swift` - String extensions for regex matching and error handling
   - `PackagePlugin+Utils.swift` - Debug description utilities for PackagePlugin types

3. **Binary Dependency** - Bundled `semver` tool in `Artifacts/semver.artifactbundle`
   - Binary target defined in Package.swift
   - Invoked via Process execution for version bumping logic

### Code Flow
1. Plugin extracts command arguments (bump type or create version)
2. Identifies target source directories to process
3. For bump: reads existing `Version.swift`, runs semver tool, writes new version
4. For create: writes new `Version.swift` with specified version
5. Generated file format is always: `enum Version { static let number = "x.y.z" }`

### Key Design Decisions
- Plugin operates on `SourceModuleTarget` only (generic or executable kinds)
- Version file is always named `Version.swift` in target root directory
- Version parsing uses regex pattern: `([0-9]+\.*)+ `
- The semver binary is executed as a subprocess rather than implemented in Swift

## Code Style

### General Guidelines

- Use explicit types for public APIs
- Prefer computed properties over methods for simple getters
- Use guard statements for early returns
- Mark models as Sendable for Swift 6 concurrency
- Keep functions under 50 lines (enforced by SwiftLint)
- Use descriptive variable names (not `i`, `j`, but `lineIndex`, `headerLevel`)

#### File Naming
- `TypeName.swift` for primary type definitions
- `TypeName+Extension.swift` or `TypeName+Utils.swift` for extensions
- `TypeName+Protocol.swift` for protocol conformances

### File Structure

Every file should start with a standard header comment block:

```swift
//
//  FileName.swift
//  ModuleName
//
//  Created by Author Name on MM/DD/YY.
//
```

- Organize imports alphabetically

### Protocol Conformance

#### Standard Pattern

Declare multiple conformances in the type declaration:

```swift
public struct UserProfile: Codable, Equatable, Identifiable, Sendable {
    // Implementation
}
```

#### Sendable Protocol

Always include `Sendable` for types used in concurrent contexts:

```swift
public struct AppError: Error, LocalizedError, Sendable { }
public enum Handedness: Codable, Equatable, Sendable { }
```

#### Protocol Extensions

Use extensions to organize protocol conformance implementations:

```swift
// MARK: - CustomStringConvertible
extension ObjectClass: CustomStringConvertible {
    public var description: String {
        switch self {
        case .basketball: return "Basketball"
        case .hoop: return "Hoop"
        }
    }
}
```

### Extension Usage

Extensions are preferred for:
1. **Adding utility methods to standard types**
2. **Organizing protocol conformances**
3. **Breaking up large type implementations**
4. **Grouping related functionality**

```swift
// MARK: - Floating Point Operations
public extension Array where Element: FloatingPoint {
    var mean: Element { sum / Element(count) }
    var sum: Element { reduce(Element(0), +) }
}
```

### Error Handling

- Prefer using typed throwing errors over generic `Error`

### Indentation and Formatting

- Use **4 spaces** for indentation (Swift standard)
- Wrap long parameter lists across multiple lines
- Align parameters vertically when wrapping

```swift
public init(
    id: UUID,
    name: String,
    height: Measurement<UnitLength>,
    handedness: Handedness
) {
    self.id = id
    self.name = name
    self.height = height
    self.handedness = handedness
}
```

### Documentation

- Include a single line between sections
- Maximum line length of 100 characters in documentation
- Use punctuation and complete sentences
- Document all public properties

<example>
```swift
/// A Swift package target.
struct Target: Equatable, Sendable {

    /// A plug-in used in a target.
    struct PluginUsage: Equatable, Sendable {
        /// The name of the plug-in target.
        let name: String

        /// The name of the package defining the plug-in target.
        let package: String?
    }

    /// A resource to bundle with the Swift package.
    struct Resource: Equatable, Sendable {

        /// The different types of localization for resources.
        public enum Localization: String, Codable, Equatable, Sendable {
            /// The default localization.
            case base
            /// The base internationalization.
            case `default`
        }

        /// The different rules for resources.
        enum Rule: Equatable, Sendable {
            /// A rule that copies the resource.
            case copy
            /// A rule that embeds the resource in code.
            case embedInCode
            /// A rule that processes the resource with a specific localization.
            case process(_ localization: Localization?)
        }

        /// The rule for the resource.
        let rule: Rule

        /// The path of the resource.
        let path: String
    }

    /// The different types of a target.
    enum TargetType: String, Sendable {
        /// A target that contains code for the Swift package's functionality.
        case regular = "target"
        /// A target that contains code for an executable's main module.
        case executable = "executableTarget"
        /// A target that contains tests for the Swift package's other targets.
        case test = "testTarget"
    }

    /// The name of the target.
    let name: String

    /// The type of the target.
    let type: TargetType

    /// A Boolean value determining whether access to package declarations from other targets in
    /// the package is allowed.
    let packageAccess: Bool

    /// The path of the target, relative to the package root.
    let path: String?

    /// Creates an instance.
    ///
    /// - Parameters:
    ///   - name: The name of the target.
    ///   - type: The type of the target.
    ///   - packageAccess: Whether access to package declarations from other targets in the package
    ///   is allowed.
    ///   - path: The path of the target, relative to the package root.
    init(
        name: String,
        type: Target.TargetType = .regular,
        packageAccess: Bool = true,
        path: String? = nil
    ) {
        self.name = name
        self.type = type
        self.packageAccess = packageAccess
        self.path = path
    }
}
```
</example>

## Requirements

- Swift 5.6+ (specified in Package.swift)
- Uses PackagePlugin framework
- Requires `--allow-writing-to-package-directory` permission flag
