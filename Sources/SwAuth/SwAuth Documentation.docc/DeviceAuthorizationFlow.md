# ``SwAuth/DeviceAuthorizationFlow``

## Getting Started

To use the Device Authorization Grant Flow, first create an instance of Keychain and then create an instance of DeviceAuthorizationFlow by filling in the information of the Web API you wish to utilize. Google's TV authentication will be used as an example.

```swift
let keychain = Keychain(service: "com.your.bundleID",
                        accessGroup: "appIdentifierPrefix.com.your.bundleID").label("Your App Name")

let googleTV = DeviceAuthorizationFlow(clientID: "YourClientID",
                                       authorizationEndpoint: URL(string: "https://oauth2.googleapis.com/device/code")!,
                                       tokenEndpoint: URL(string: "https://oauth2.googleapis.com/device/code")!,
                                       keychain: keychain
                                       scopes: "email provider")
// Google's device flow specifically requires additional parameters:
googleTV.additionalTokenRequestParams = ["client_secret": "YourClientSecret"]
googleTV.additionalRefreshTokenBodyParams = ["client_id": "YourClientID", "client_secret": "YourClientSecret"]
```

Now send the authorization request and handle the response:

```swift
let deviceAuthReq = try await googleTV.deviceFlowAuthorizationRequest()
try await googleTV.authorizationResponseHandler(for: deviceAuthReq)
```

Obviously, you will need to display the authorization code and URL to the user. See ``DeviceAuthResponse`` for more information.

Assuming no errors were thrown, you can now successfully make an authorized HTTP request to the endpoint of your choice and print the resulting JSON:

```swift
let request = HTTPRequest(endpoint: URL(string: "https://openidconnect.googleapis.com/v1/userinfo")!)

let response = try await googleTV.authenticatedRequest(for: request)

// Assuming no errors were thrown
print(response.json())
```

## Topics

### Initialization

- ``init(clientID:authorizationEndpoint:tokenEndpoint:keychain:)``
- ``init(clientID:authorizationEndpoint:tokenEndpoint:keychain:scopes:)``

### Options

- ``additionalAuthorizationParams``
- ``additionalTokenRequestParams``
- ``additionalRefreshTokenBodyParams``
- ``scopes``
- ``authHeaderTokenType``

### Authorization

- ``deviceFlowAuthorizationRequest()``
- ``authorizationResponseHandler(for:)``

### Displaying Authorization Info

- ``DeviceAuthResponse``

### Read-only Properties

- ``authorizationParams``
- ``tokenRequestParams``

### Initialized Properties

- ``authorizationEndpoint``
- ``clientID``
- ``keychain``
- ``tokenEndpoint``
