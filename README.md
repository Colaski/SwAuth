<!-- omit in toc -->
# SwAuth ![License](https://img.shields.io/github/license/colaski/swauth?color=lightgrey&style=flat-square) ![Version](https://img.shields.io/github/v/release/colaski/swauth?style=flat-square)

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/b38ed7450d054e29a0381ad3c11df264)](https://app.codacy.com/gh/Colaski/SwAuth?utm_source=github.com&utm_medium=referral&utm_content=Colaski/SwAuth&utm_campaign=Badge_Grade_Settings)
[![Build](https://github.com/Colaski/SwAuth/actions/workflows/build.yml/badge.svg)](https://github.com/Colaski/SwAuth/actions/workflows/build.yml)
![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-success?style=flat-square)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%2B%20%7C%20macOS%2012%2B%20%7C%20watchOS%208%2B%20%7C%20tvOS%2015%2B-blue?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.5-orange?style=flat-square)

SwAuth is an OAuth 2.0 HTTP request library written in Swift for iOS 15.0+, macOS 12.0+, watchOS 8.0+, and tvOS 15.0+.

- [Features](#features)
- [Requirements](#requirements)
- [Installation/Integration](#installationintegration)
  - [Swift Package](#swift-package)
  - [App](#app)
- [Basic Usage](#basic-usage)
- [Contributing](#contributing)
- [License](#license)

## Features

- [x] Beautiful readable syntax with async/await! Kiss completion handler hell and the closure jungle goodbye!
- [x] Supports Authorization Code Grant (RFC 6749/6750), Proof Key for Code Exchange (PKCE) extension for Authorization Code Grant (RFC 7636), and the Device Authorization Grant (RFC 8628).
- [x] Support for all Apple device platforms.
- [x] Retry errored requests.
- [x] Automatically refreshes tokens.
- [x] Tokens stored on Keychain and cross-site request forgery mitigation by default.
- [x] Easily deal with JSON responses with [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) built-in.
- [x] Easily integrate with SwiftUI.
- [x] [Complete, meticulous, thorough, documentation.](https://swauth.netlify.app/documentation/Swauth)
- [x] Errors that are probably, maybe, useful.
- [x] Built on [SwiftNIO](https://github.com/apple/swift-nio) with [AsyncHTTPClient](https://github.com/swift-server/async-http-client).
- [x] QR Code for the Device Authorization Flow (tvOS/watchOS).
- [x] Sample/Example Apps.

## Requirements

- Xcode 13+
- iOS 15.0+ | macOS 12.0+ | watchOS 8.0+ | tvOS 15.0+

## Installation/Integration

### Swift Package

Use the Swift Package Manager to add SwAuth to your project! Simply add the package to dependencies in your `Package.swift`:

```swift
let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/Colaski/SwAuth.git", from: "1.0.0"),
    ]
)
```

### App

Select `File > Add Packages` and enter `https://github.com/Colaski/SwAuth.git`

## Basic Usage

1. Import SwAuth in files you wish to use it's amazing features:

    ```swift
    import SwAuth
    ```

2. Create an instance of keychain:

    ```swift
    let keychain = Keychain(service: "com.your.bundleID",
                            accessGroup: "appIdentifierPrefix.com.your.bundleID").label("Your App Name")
    ```

3. Create an instance of the proper authorization flow for your Web API.

    ```swift
    let keychain = Keychain(service: "com.your.bundleID",
                            accessGroup: "appIdentifierPrefix.com.your.bundleID").label("Your App Name")

    let spotify = PKCEAuthorizationFlow(clientID: "YourClientID",
                                        authorizationEndpoint: URL(string: "https://accounts.spotify.com/authorize")!,
                                        tokenEndpoint: URL(string: "https://accounts.spotify.com/api/token")!,
                                        redirectURI: "someapp://callback",
                                        keychain: keychain,
                                        scopes: "user-follow-modify")
    ```

4. Start an ASWebAuthenticationSession like in the [example app](https://github.com/Colaski/SwAuth/blob/main/SwAuthTestApp/SwAuthTestApp/ProviderView.swift#L94) with the instance's authorization URL:

    ```swift
    spotify.authorizationURL
    ```

5. Pass the callback URL from the ASWebAuthenticationSession into the provided handler method:

    ```swift
    do {
        try await spotify.authorizationResponseHandler(for: callbackURL)
    } catch {
        print(error.localizedDescription)
    }
    ```

6. Make an authorized request:

    ```swift
    do {
        // https://developer.spotify.com/documentation/web-api/reference/#/operations/follow-artists-users
        var request = HTTPRequest(endpoint: URL(sting: "https://api.spotify.com/v1/me/following")!)
        request.httpMethod = .PUT
        request.endpointQueryItems = ["type": "artist"]
        request.httpBody = ["ids": ["5K4W6rqBFWDnAN6FQUkS6x"]]
        request.bodyEncoding = .JSON

        // Send an authenticated HTTP request, this one will follow the artist Kanye West on Spotify.
        let json = try await spotify.authenticatedRequest(for: request, numberOfRetries: 2).json()
        
        // Prints the JSON output
        print(json)
    } catch {
        print(error.localizedDescription)
    }
    ```

For more information, read my beautiful documentation: [https://swauth.netlify.app/documentation/Swauth](https://swauth.netlify.app/documentation/Swauth)

## Contributing

Check out [CONTRIBUTING.md](./CONTRIBUTING.md) for information!

## License

SwAuth its self is licensed under the [MIT License](./LICENSE), however please take notice of the [NOTICE](./NOTICE.md) file in the root of this repository. Also, make sure to check the respective licenses of this library's dependencies before releasing your project.