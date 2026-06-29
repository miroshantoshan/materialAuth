<p align="center">
  <img src="Assets/MaterialAuthIcon.png" alt="materialAuth logo" width="128" />
</p>

<h1 align="center">materialAuth</h1>

<p align="center">
  <img src="https://img.shields.io/badge/lang-Swift-white?style=for-the-badge" alt="Swift">
  <img src="https://img.shields.io/badge/for--white?style=for-the-badge" alt="macOS">
  <img src="https://img.shields.io/badge/lang-RU | ENG-white?style=for-the-badge" alt="Languages">
</p>

MaterialAuth is a compact native macOS TOTP authenticator with a clean Material Design 3-inspired interface.

## Features

- 6- and 8-digit TOTP codes with 30-second refresh
- SHA-1, SHA-256, and SHA-512 algorithms
- `otpauth://totp/...` link import
- QR-code import from screenshots or image files
- Manual account creation
- Secret storage in macOS Keychain
- One-click code copying
- Search
- System, light, and dark appearance modes
- Four Material 3-inspired color palettes
- Local service icons for popular providers

## Requirements

- macOS 14 or newer
- Swift 6 toolchain
- Xcode 16 or newer for full app development

## Run

```bash
swift run MaterialAuth
```

You can also open `Package.swift` in Xcode.

## Build The App

```bash
./build_app.sh
```

The packaged app will be created at:

```text
dist/MaterialAuth.app
```

The build script creates a release build, copies `Info.plist` and `Resources/MaterialAuth.icns` into the app bundle, clears extended attributes, and signs the app ad hoc for local use.

## Project Structure

```text
.
├── Assets/
│   └── MaterialAuthIcon.png
├── Resources/
│   └── MaterialAuth.icns
├── Sources/
│   └── MaterialAuth/
├── Info.plist
├── Package.swift
└── build_app.sh
```

## Privacy

MaterialAuth stores account metadata in `UserDefaults` and stores TOTP secrets in the macOS Keychain using a local generic-password service. Secrets are not committed to the repository and are not stored in plaintext project files.

## License

MaterialAuth is released under the MIT License. See [LICENSE](LICENSE) for details.
