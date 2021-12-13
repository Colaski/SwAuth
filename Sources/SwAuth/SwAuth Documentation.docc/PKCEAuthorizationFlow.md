# ``SwAuth/PKCEAuthorizationFlow``

## Getting Started

To use the PKCE Authorization Code Flow, first create an instance of Keychain and then create an instance of PKCEAuthorizationFlow by filling in the information of the Web API you wish to utilize. Spotify will be used as an example.

```swift
let keychain = Keychain(service: "com.your.bundleID",
                        accessGroup: "appIdentifierPrefix.com.your.bundleID").label("Your App Name")

var spotify = PKCEAuthorizationFlow(clientID: "YourClientID",
                                    authorizationEndpoint: URL(string: "https://accounts.spotify.com/authorize")!,
                                    tokenEndpoint: URL(string: "https://accounts.spotify.com/api/token")!,
                                    redirectURI: "someapp://callback",
                                    keychain: keychain)
spotify.additionalRefreshTokenBodyParams = ["client_id": "YourClientID"] // Spotify specifically requires the client ID to be included in the refresh token's body parameters.
```

I can now get the authorization URL my user will follow like so:

```swift
let authURL = spotify.authorizationURL
```

SwiftUI users, I recommend using [BetterSafariView's](https://github.com/stleamist/BetterSafariView) ASWebAuthenticationSession for following the authorization URL.

Assuming the user authorizes your application, pass the callback URL into ``authorizationResponseHandler(for:)`` (but of course take into account proper error handling):

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

- ``init(clientID:authorizationEndpoint:tokenEndpoint:redirectURI:keychain:)``
- ``init(clientID:authorizationEndpoint:tokenEndpoint:redirectURI:keychain:scopes:)``

### Options

Additional options can be configured for the instance, for example:

```swift
authFlowInstance.additionalAuthorizationParams = ["Additional Key": "Value for Additional Key"]
```

- ``additionalAuthorizationParams``
- ``additionalTokenRequestParams``
- ``additionalRefreshTokenBodyParams``
- ``scopes``
- ``authHeaderTokenType``

### Handle the Callback

- ``authorizationResponseHandler(for:)``

### Read-only Properties

- ``authorizationURL``
- ``authorizationParams``
- ``tokenRequestParams``

### Initialized Properties

- ``authorizationEndpoint``
- ``clientID``
- ``keychain``
- ``redirectURI``
- ``tokenEndpoint``
