//
// DeviceAuthorizationFlow.swift
//
// Copyright (c) 2021 Colaski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation
import KeychainAccess
import enum NIOHTTP1.HTTPMethod

/**
 The Device Authorization Grant extension to the OAuth 2.0 Authorization Code Grant according to to
 RFC 8628.
 
 As per the [IETF](https://datatracker.ietf.org/doc/html/rfc8628): "The OAuth 2.0 device
 authorization grant is designed for Internet-connected devices that either lack a browser to perform a
 user-agent-based authorization or are input constrained to the extent that requiring the user to input
 text in order to authenticate during the authorization flow is impractical." So, this authorization
 flow is particularly useful for tvOS and perhaps watchOS as well.
 
 Conforms to the ``Swauthable`` protocol.
 
 See ``init(clientID:authorizationEndpoint:tokenEndpoint:keychain:)`` and/or
 ``init(clientID:authorizationEndpoint:tokenEndpoint:keychain:scopes:)``
 for initialization examples.
 */
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
open class DeviceAuthorizationFlow: Swauthable {
    // MARK: - Properties
    /// The client identifier issued by the server. Is initialized.
    public let clientID: String

    /// Instance of KeychainAccess.  Is initialized.
    public let keychain: Keychain

    /// The scopes you want your app to be authorized for, separated by spaces.
    open var scopes: String?

    /// The server authorization endpoint URL. Is initialized.
    public let authorizationEndpoint: URL
    /// The body parameters for the authorization endpoint request. Read-only.
    ///
    /// Not including ``scopes`` and ``additionalAuthorizationParams``, this property is:
    /// ```swift
    /// [
    ///     "client_id": clientID
    /// ]
    /// ```
    open var authorizationParams: [String: String] {
        var authParams = [
            "client_id": clientID
        ]
        if scopes != nil { authParams.merge(with: ["scope": scopes!]) }
        if additionalAuthorizationParams != nil {
            authParams.merge(with: additionalAuthorizationParams!)
        }
        return authParams
    }
    /// Additional a authorization parameters.
    ///
    /// See `authorizationParams` for the provided parameters.
    open var additionalAuthorizationParams: [String: String]?

    /// The server's token endpoint URL. Is initialized.
    public let tokenEndpoint: URL
    /// The HTTP body parameters for the token request. Read-only.
    ///
    /// Not including ``additionalTokenRequestParams``, this property is:
    /// ```swift
    /// [
    ///     "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
    ///     "device_code": deviceCode, // The device code provided by the authorization request.
    ///     "client_id": clientID
    /// ]
    /// ```
    open var tokenRequestParams: [String: String] {
        var parms = [
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
            "device_code": _deviceFlowAuthResponse?.deviceCode ?? "",
            "client_id": clientID
        ]
        if additionalTokenRequestParams != nil {
            parms.merge(with: additionalTokenRequestParams!)
        }
        return parms
    }
    /// Any additional parameters for the token request.
    ///
    /// See ``tokenRequestParams`` for the provided parameters.
    open var additionalTokenRequestParams: [String: String]?

    /// **Ignore if the server not provide a refresh token.**
    /// Any additional HTTP body parameters for the token refresh request. The key/value pairs for
    /// "refresh\_token" and "grant\_type" are handled internally when an
    ///  ``Swauthable/authenticatedRequest(for:numberOfRetries:)``
    /// is made.
    open var additionalRefreshTokenBodyParams: [String: String]?

    /// Some APIs may use a different key for their authorization header's token type than the one
    /// provided by the token request response.
    ///
    /// For example, Github uses "token", however their token response type is "bearer".
    open var authHeaderTokenType: String?

    /// The  ``DeviceFlowAuthResponse-swift.struct``from a call to the
    /// ``deviceFlowAuthorizationRequest()`` method. Is nil if a call to
    /// ``deviceFlowAuthorizationRequest()`` has not yet been made.
    private var _deviceFlowAuthResponse: DeviceAuthResponse?

    // MARK: - Methods
    /**
     Sends a POST request to the authorization endpoint. Returns a
     ``DeviceAuthorizationFlow/DeviceAuthResponse`` instance.
     
     If an HTTP error occurs, the HTTP request to the authorization endpoint will be retried once.
     
     - Important: After calling this method, please call the
     ``DeviceAuthorizationFlow/authorizationResponseHandler(for:)`` method.
     */
    open func deviceFlowAuthorizationRequest() async throws -> DeviceAuthResponse {
        lazy var request = HTTPRequest(
            endpoint: authorizationEndpoint,
            withBody: authorizationParams,
            bodyEncoding: .FORM
        )
        request.httpMethod = .POST

        var loop = (authResponse: DeviceAuthResponse?(nil), retries: UInt8(0))
        repeat {
            do {
                let response = try await http(request: request).json()
                let authResponse = try DeviceAuthResponse(fromJSON: response)
                self._deviceFlowAuthResponse = authResponse
                return authResponse
            } catch {
                if loop.retries < 1 {
                    loop.retries += 1
                    continue
                } else {
                    throw error
                }
            }
        } while loop.authResponse == nil
        return loop.authResponse!
    }

    /**
     Handles the ``DeviceAuthorizationFlow/DeviceAuthResponse`` ``Response``  from a call to
     ``deviceFlowAuthorizationRequest()``. Sends a HTTP request to the initialized
     token endpoint for the tokens. Polling will only happen for 15 minutes.
     
     Tokens are saved to the Keychain instance provided by the initializer. The tokens are saved using
     the instance's client id and the string "tokens" separated by a colon as the key. For example:
     "9d73bfb50b304543b35f41d427e6b76c:tokens"
     
     If an HTTP error occurs, the token request will be retried once.
     
     - Parameter for: The ``DeviceAuthorizationFlow/DeviceAuthResponse`` returned
     from a ``deviceFlowAuthorizationRequest()`` call.
     */
    open func authorizationResponseHandler(for response: Response) async throws {
        guard let authResponse = response as? DeviceAuthResponse else {
            throw SwAuthError.authorizationFailure(reason: .responseNotDeviceFlowAuthResponse)
        }

        lazy var request = HTTPRequest(endpoint: tokenEndpoint,
                                       withBody: tokenRequestParams,
                                       bodyEncoding: .FORM)
        request.httpMethod = .POST

        var interval = authResponse.interval
        var success = false
        let now = Date()
        // Super evil polling.
        repeat {
            // 😈
            sleep(interval)
            guard authResponse.isExpired == false else {
                throw SwAuthError.authorizationFailure(reason: .deviceCodeExpired)
            }
            // Stops polling after 15min
            guard now.timeIntervalSinceNow > -900 else { throw SwAuthError.pollingTooLong }
            do {
                try await tokenRequest(request: request)
                success = true
            } catch SwAuthError.httpError(let error) {
                guard error.contains("access_denied") == false else {
                    throw SwAuthError.authorizationFailure(reason: .denied)
                }
                guard error.contains("expired_token") == false else {
                    throw SwAuthError.authorizationFailure(reason: .deviceCodeExpired)
                }
                if error.contains("slow_down") { interval += 5 }
                // Starts loop again.
                if  error.contains("authorization_pending") || error.contains("slow_down") {
                    continue
                } else {
                    throw SwAuthError.httpError(json: error)
                }
            }

        } while success == false
    }

    // MARK: - Initializers
    /**
     Initializes a DeviceAuthorizationFlow object.
     
     This initializer is called by
     ``init(clientID:authorizationEndpoint:tokenEndpoint:keychain:scopes:)``.
     
     Example Code:
     ```swift
     // the "accessGroup" parameter is only necessary if you wish to share the keychain across
     // multiple targets using a keychain sharing entitlement
     let keychain = Keychain(service: "your.app.bundleID", accessGroup: "appIdentifierPrefix.your.app.bundleID")
        .label("Your App Name")
     
     let domain = DeviceAuthorizationFlow(
        clientID: "9d73bfb50b304543b35f41d427e6b76c",
        authorizationEndpoint: URL(string: "https://domain.com/authorize")!,
        tokenEndpoint: URL(string: "https://domain.com/token")!,
        keychain: keychain
     )
     ```
     
     - Parameters:
        - clientID: The client identifier issued by the server.
        -  authorizationEndpoint: The server authorization endpoint URL.
        -  tokenEndpoint: The server token endpoint URL.
        - Keychain: An instance of Keychain from KeychainAccess.
        [Full KeychainAccess
         documentation](https://github.com/kishikawakatsumi/KeychainAccess).
     */
    public init(clientID: String,
                authorizationEndpoint: URL,
                tokenEndpoint: URL,
                keychain: Keychain) {
        self.clientID = clientID
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.keychain = keychain
    }
    /**
     Initializes a DeviceAuthorizationFlow object, with scopes.
     
     This initializer calls
     ``DeviceAuthorizationFlow/init(clientID:authorizationEndpoint:tokenEndpoint:keychain:)``,
     and initializes the scopes property.
     
     Example Code:
     ```swift
     // the "accessGroup" parameter is only necessary if you wish to share the keychain across
     // multiple targets using a keychain sharing entitlement
     let keychain = Keychain(service: "your.app.bundleID", accessGroup: "appIdentifierPrefix.your.app.bundleID")
        .label("Your App Name")
     
     let domain = DeviceAuthorizationFlow(
        ...
        // The same as the other initializer.
        ...
        scopes: "read-email-address modify-account"
     )
     ```
     
     - Parameters:
        - clientID: The client identifier issued by the server.
        -  authorizationEndpoint: The server authorization endpoint URL.
        -  tokenEndpoint: The server token endpoint URL.
        - Keychain: An instance of Keychain from KeychainAccess.
        [Full KeychainAccess
         documentation](https://github.com/kishikawakatsumi/KeychainAccess).
        - scopes: The scopes you want your app to be authorized for, separated by spaces.
     */
    public convenience init(clientID: String,
                            authorizationEndpoint: URL,
                            tokenEndpoint: URL,
                            keychain: Keychain,
                            scopes: String) {
        self.init(clientID: clientID,
                  authorizationEndpoint: authorizationEndpoint,
                  tokenEndpoint: tokenEndpoint,
                  keychain: keychain)
        self.scopes = scopes
    }
}
