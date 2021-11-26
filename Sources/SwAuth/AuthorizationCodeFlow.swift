//
// AuthorizationCodeFlow.swift
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
 The OAuth 2.0 Authorization Code Grant according to RFC 6749/6750.
 
 - Warning: The OAuth 2.0 Authorization Code Flow is not secure for native applications, it should only be
 used when ABSOLUTELY NECESSARY. If you are connecting to your own HTTP server, please implement RFC 7636
 and utilize the ``PKCEAuthorizationFlow``. Unfortunately, if you do not have control over the server,
 this may be your only option.
 
 Conforms to the ``Swauthable`` protocol.
 
 See ``init(clientID:clientSecret:authorizationEndpoint:tokenEndpoint:redirectURI:keychain:)``
 and/or ``init(clientID:clientSecret:authorizationEndpoint:tokenEndpoint:redirectURI:keychain:scopes:)``
 for initialization examples.
 */
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
open class AuthorizationCodeFlow: Swauthable {
    // MARK: - Properties
    /// The client identifier issued by the server. Is initialized.
    public let clientID: String
    /// The client secret issued by the server. Is initialized.
    let clientSecret: String

    /// Instance of KeychainAccess. Is initialized.
    public let keychain: Keychain

    /// The application's redirect URI. Is initialized.
    public let redirectURI: String

    /// The scopes you want your app to be authorized for, separated by spaces.
    open var scopes: String?

    /// The server authorization endpoint URL. Is initialized.
    public let authorizationEndpoint: URL
    /// The parameters for the ``AuthorizationCodeFlow/authorizationURL``. Read-only.
    /// 
    /// Not including ``scopes`` and ``additionalAuthorizationParams``,  this property is:
    /// ```swift
    /// [
    ///     "response_type": "code",
    ///     "client_id": clientID,
    ///     "state": state,
    ///     "redirect_uri": redirectURI
    /// ]
    /// ```
    open var authorizationParams: [String: String] {
        var parms = [
            "response_type": "code",
            "client_id": clientID,
            "state": state,
            "redirect_uri": redirectURI
        ]
        if scopes != nil { parms.merge(with: ["scope": scopes!]) }
        if additionalAuthorizationParams != nil {
            parms.merge(with: additionalAuthorizationParams!)
        }
        return parms
    }
    /// Additional authorization parameters.
    ///
    /// See ``authorizationParams`` for the provided parameters.
    open var additionalAuthorizationParams: [String: String]?

    /// A URL constructed from the ``authorizationEndpoint`` and ``authorizationParams`` for use with an
    /// ASWebAuthenticationSession. Read-only.
    open var authorizationURL: URL {
        return authorizationEndpoint.addQueryItems(authorizationParams)
    }

    /// The server's token endpoint URL. Is initialized.
    public let tokenEndpoint: URL
    /// The HTTP body parameters for the token request. Read-only.
    ///
    /// The key/value pair for "code" is handled by the
    ///  ``authorizationResponseHandler(for:)``
    /// method.
    ///
    /// Other than the key/value pair for "code" and ``additionalTokenRequestParams``,
    /// this property is:
    /// ```swift
    /// [
    ///     "grant_type": "authorization_code",
    ///     "redirect_uri": redirectURI,
    ///     "client_id": clientID,
    ///     "client_secret": clientSecret
    /// ]
    /// ```
    open var tokenRequestParams: [String: String] {
        var parms = [
            "grant_type": "authorization_code",
            "redirect_uri": redirectURI,
            "client_id": clientID,
            "client_secret": clientSecret
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

    /// **Ignore if the Web API does not provide a refresh token.**
    /// Any additional HTTP body parameters for the token refresh request. The key/value pairs for
    /// "refresh\_token" and "grant\_type" are handled internally when a
    /// ``Swauthable/authenticatedRequest(for:numberOfRetries:)``
    /// is made.
    open var additionalRefreshTokenBodyParams: [String: String]?

    /// A random string of 8 characters to be used as further verification.
    private var state: String

    /// Some servers may use a different key for their authorization header's token type than the one
    /// provided by the token request response.
    ///
    /// For example, Github uses "token", however their token response type is "bearer".
    open var authHeaderTokenType: String?

    /// Some servers may allow or want the client id and client secret to be parameters in a HTTP request's
    /// body instead of a Basic authorization. Set false if that is the case, otherwise a Basic Authorization will
    /// be used by default.
    open var useBasicAuthorization = true

    // MARK: - Methods
    /// Handles the callback URL from an ASWebAuthenticationSession
    /// and sends a HTTP request to the initialized token endpoint for the tokens.
    ///
    /// Tokens are saved to the Keychain instance provided by the initializer. The tokens are saved using
    /// the instance's client id and the string "tokens" separated by a colon as the key. For example:
    /// "9d73bfb50b304543b35f41d427e6b76c:tokens"
    ///
    /// If an HTTP error occurs, the token request will be retried once.
    ///
    /// - Parameter for: The callback URL from a ASWebAuthenticationSession.
    open func authorizationResponseHandler(for response: Response) async throws {
        guard let url = response as? URL else {
            throw SwAuthError.authorizationFailure(reason: .responseNotURL)
        }

        let dict = try url.queryAsDictionary()
        guard url.fragment == nil else {
            throw SwAuthError.authorizationFailure(reason: .authorizationError(with: url.fragment!))
        }
        guard let authCode = dict["code"],
              let authState = dict["state"] else {
                  throw SwAuthError.authorizationFailure(reason: .authCallbackInvalid)
              }
        // Prevents possible cross-site forgery.
        guard authState == state else {
            throw SwAuthError.authorizationFailure(reason: .stateIncorrect)
        }

        var httpBody = tokenRequestParams
        httpBody.merge(with: ["code": authCode])

        lazy var request = HTTPRequest(endpoint: tokenEndpoint)
        request.httpMethod = .POST

        if useBasicAuthorization {
            httpBody.removeValue(forKey: "client_id")
            httpBody.removeValue(forKey: "client_secret")
            request.httpBody = httpBody

            let stringData = "\(clientID):\(clientSecret)".data(using: .utf8)
            let base64 = stringData!.base64EncodedString()
            request.additionalHTTPHeaders = ["Authorization": "Basic \(base64)"]
        } else {
            request.httpBody = httpBody
        }

        try await tokenRequest(request: request)
    }

    // MARK: - Initializers
    /**
     Initializes an AuthorizationCodeFlow object.
     
     This initializer is called by
     ``init(clientID:clientSecret:authorizationEndpoint:tokenEndpoint:redirectURI:keychain:scopes:)``.
     
     Example Code:
     ```swift
     // the "accessGroup" parameter is only necessary if you wish to share the keychain across
     // multiple targets using a keychain sharing entitlement
     let keychain = Keychain(service: "your.app.bundleID", accessGroup: "appIdentifierPrefix.your.app.bundleID")
         .label("Your App Name")

     let domain = AuthorizationCodeFlow(
         clientID: "9d73bfb50b304543b35f41d427e6b76c",
         clientSecret: "661a155dfdca47ec96f48fd767209b7d",
         authorizationEndpoint: URL(string: "https://domain.com/authorize")!,
         tokenEndpoint: URL(string: "https://domain.com/token")!,
         redirectURI: "appname://callback",
         keychain: keychain
     )
     ```
     
     - Parameters:
        - clientID: The client identifier issued by the server.
        - clientSecret: The client secret issued by the server. Use nil if one was not provided.
        -  authorizationEndPoint: The server authorization endpoint URL.
        -  tokenEndpoint: The server token endpoint URL.
        - redirectURI: Your application's redirect URI.
        - Keychain: An instance of Keychain from KeychainAccess.
        [Full KeychainAccess
         documentation](https://github.com/kishikawakatsumi/KeychainAccess).
     */
    public init(clientID: String,
                clientSecret: String?,
                authorizationEndpoint: URL,
                tokenEndpoint: URL,
                redirectURI: String,
                keychain: Keychain) {
        self.clientID = clientID
        self.clientSecret = clientSecret ?? ""
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.redirectURI = redirectURI
        self.keychain = keychain
        self.state = String.random(ofLength: 8)
    }
    /**
     Initializes an AuthorizationCodeFlow object, with scopes.
     
     This initializer calls
     ``AuthorizationCodeFlow/init(clientID:clientSecret:authorizationEndpoint:tokenEndpoint:redirectURI:keychain:)``,
     and initializes the ``scopes`` property.
     
     Example Code:
     ```swift
     // the "accessGroup" parameter is only necessary if you wish to share the keychain across
     // multiple targets using a keychain sharing entitlement
     let keychain = Keychain(service: "your.app.bundleID", accessGroup: "appIdentifierPrefix.your.app.bundleID")
         .label("Your App Name")

     let domain = AuthorizationCodeFlow(
         ...
         // The same as the other initializer.
         ...
         scopes: "read-email-address modify-account"
     )
     ```
     
     - Parameters:
        - clientID: The client identifier issued by the server.
        - clientSecret: The client secret issued by the server. Use nil if one was not provided.
        -  authorizationEndPoint: The server authorization endpoint URL.
        -  tokenEndpoint: The server token endpoint URL.
        - redirectURI: Your application's redirect URI.
        - Keychain: An instance of Keychain from KeychainAccess.
        [Full KeychainAccess
         documentation](https://github.com/kishikawakatsumi/KeychainAccess).
        - scopes: The scopes you want your app to be authorized for, separated by spaces.
     */
    public convenience init(clientID: String,
                            clientSecret: String?,
                            authorizationEndpoint: URL,
                            tokenEndpoint: URL,
                            redirectURI: String,
                            keychain: Keychain,
                            scopes: String) {
        self.init(clientID: clientID,
                  clientSecret: clientSecret,
                  authorizationEndpoint: authorizationEndpoint,
                  tokenEndpoint: tokenEndpoint,
                  redirectURI: redirectURI,
                  keychain: keychain)
        self.scopes = scopes
    }
}
