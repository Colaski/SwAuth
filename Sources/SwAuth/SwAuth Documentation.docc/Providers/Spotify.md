# ``SwAuth/Spotify``

## Getting Started

To use Spotify, first create an instance of Keychain and then create an instance of Spotify by filling in your apps documentation. You can create an app on your [Spotify developer dashboard](https://developer.spotify.com/dashboard/applications).

```swift
let keychain = Keychain(service: "com.your.bundleID",
                        accessGroup: "appIdentifierPrefix.com.your.bundleID").label("Your App Name")

let spotify = Spotify(clientID: "YourClientID",
                      redirectURI: "callbackURI://", // Make sure this is the same as you set on your developer dashboard
                      keychain: keychain,
                      scopes: "user-follow-modify")
```

I can now get the authorization URL my user will follow like so:

```swift
let authURL = spotify.authorizationURL
```

SwiftUI users, I recommend using [BetterSafariView's](https://github.com/stleamist/BetterSafariView) ASWebAuthenticationSession for following the authorization URL.

Assuming the user authorizes your application, pass the callback URL into ``PKCEAuthorizationFlow/authorizationResponseHandler(for:)`` (but of course take into account proper error handling):

```swift
try await spotify.authorizationResponseHandler(for: callbackURL)
```

Assuming no errors were thrown, you can now successfully make an authorized HTTP request to the endpoint of your choice and print the resulting JSON:

```swift
let request = HTTPRequest(endpoint: URL(string: "https://api.spotify.com/v1/browse/new-releases")!)

let response = try await spotify.authenticatedRequest(for: request)

// Assuming no errors were thrown
print(response.json())
```

## Topics

### Initialization

- ``init(clientID:redirectURI:keychain:scopes:)``

### Handle the Callback

- ``PKCEAuthorizationFlow/authorizationResponseHandler(for:)``
