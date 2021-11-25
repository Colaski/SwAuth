# SwAuth

SwAuth is a OAuth 2.0 library for iOS 15.0+, macOS 12.0+, watchOS 8.0+, and tvOS 15.0+ written in Swift.

## Features

- [x] Usable and beautiful syntax with async/await! Say goodbye to completion handler hell!
- [x] Authorization Code Grant (RFC 6749/6750), Proof Key for Code Exchange (PKCE) extension for Authorization Code Grant (RFC 7636), and the Device Authorization Grant (RFC 8628).
- [x] Support for all Apple platforms.
- [x] Retry errored requests.
- [x] Built on [SwiftNIO](https://github.com/apple/swift-nio) with [AsyncHTTPClient](https://github.com/swift-server/async-http-client). (Suck it URLSession)
- [x] [Complete. Meticulous. Thorough. documentation 😰.](https://swauth.netlify.app/documentation/Swauth)
- [x] Device Authorization QR Code for tvOS/watchOS.
- [x] Easily integrate with SwiftUI.
- [x] Sample/Example Apps.
- [x] Automatically refresh tokens.
- [x] Tokens securely stored on the Keychain.
- [x] Easily deal with JSON responses.
- [x] Useful errors (mostly).

## Requirments

- Xcode 13+
- iOS 15.0+ | macOS 12.0+ | watchOS 8.0+ | tvOS 15.0+

## Installation/Integration

Use the Swift Package Manager to add SwAuth to your project! Simply add the package to your dependencies in your `Package.swift`: 

```swift
let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/Colaski/SwAuth.git", from: "1.0.0"),
    ]
)
```

## Usage

1. Import SwAuth in files you wish to use it's amazing features:
```swift
import SwAuth
```

2. Read the docs 🤣 [https://swauth.netlify.app/documentation/Swauth](https://swauth.netlify.app/documentation/Swauth)
