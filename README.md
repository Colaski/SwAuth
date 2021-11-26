<!-- omit in toc -->
# SwAuth

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/b38ed7450d054e29a0381ad3c11df264)](https://app.codacy.com/gh/Colaski/SwAuth?utm_source=github.com&utm_medium=referral&utm_content=Colaski/SwAuth&utm_campaign=Badge_Grade_Settings)
![Travis](https://app.travis-ci.com/Colaski/SwAuth.svg?branch=main)
![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-Compatible-brightgreen)
![Swift](https://img.shields.io/badge/Swift-5.5-orange)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2015.0%2B%20%7C%20macOS%2012.0%2B%20%7C%20watchOS%208.0%2B%20%7C%20tvOS%2015.0%2B-blue)

SwAuth is an OAuth 2.0 HTTP request library written in Swift iOS 15.0+, macOS 12.0+, watchOS 8.0+, and tvOS 15.0+.

- [Features](#features)
- [Requirements](#requirements)
- [Installation/Integration](#installationintegration)
- [Basic Usage](#basic-usage)
- [Contributing](#contributing)

## Features

- [x] Usable and beautiful syntax with async/await! Kiss completion handler hell and the closure jungle goodbye!
- [x] Supports Authorization Code Grant (RFC 6749/6750), Proof Key for Code Exchange (PKCE) extension for Authorization Code Grant (RFC 7636), and the Device Authorization Grant (RFC 8628).
- [x] Support for all Apple device platforms.
- [x] Retry errored requests.
- [x] Automatically refreshes tokens.
- [x] Tokens stored on Keychain and cross-site request forgery mitigation by default.
- [x] Easily deal with JSON responses with [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) built-in.
- [x] Easily integrate with SwiftUI.
- [x] [Complete, meticulous, thorough, documentation.](https://swauth.netlify.app/documentation/Swauth)
- [x] Errors that are probably, maybe actually useful.
- [x] Built on [SwiftNIO](https://github.com/apple/swift-nio) with [AsyncHTTPClient](https://github.com/swift-server/async-http-client).
- [x] QR Code for the Device Authorization Flow (tvOS/watchOS).
- [x] Sample/Example Apps.

## Requirements

- Xcode 13+
- iOS 15.0+ | macOS 12.0+ | watchOS 8.0+ | tvOS 15.0+

## Installation/Integration

Use the Swift Package Manager to add SwAuth to your project! Simply add the package to dependencies in your `Package.swift`: 

```swift
let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/Colaski/SwAuth.git", from: "1.0.0"),
    ]
)
```

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

    // Send an authenticated HTTP request, this one will follow the artist Kanye on Spotify.
    let json = try await spotify.authenticatedRequest(for: request, numberOfRetries: 2).json()
    
    // Prints the JSON output
    print(json)
} catch {
    print(error.localizedDescription)
}
```

For more information, read my beautiful documentation: [https://swauth.netlify.app/documentation/Swauth](https://swauth.netlify.app/documentation/Swauth)

## Contributing

Contributions are welcome!

Make sure swift is installed and then
```bash
git clone https://github.com/Colaski/SwAuth.git
cd SwAuth
swift build
```

Make your changes and submit and a PR for review!

Nice to have list:

- [ ] Include ready to go implementations of Web API's with endpoints like in the [example app](https://github.com/Colaski/SwAuth/blob/main/SwAuthTestApp/SwAuthTestApp/Spotify.swift)
    - Perhaps Spotify, Google, Azure/Microsoft, Github etc.
    
- [ ] OAuth 1.0 support
