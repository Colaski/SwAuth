//
// PKCEAuthorizationFlow.swift
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
import NIOHTTP1
import CryptoKit

/**
 The Proof Key for Code Exchange (PKCE) extension to the OAuth 2.0 Authorization Code Grant according to
 RFC 7636.
 
 Conforms to the ``Swauthable`` protocol.
 
 See
 ``init(clientID:authorizationEndpoint:tokenEndpoint:redirectURI:keychain:)`` and/or
 ``init(clientID:authorizationEndpoint:tokenEndpoint:redirectURI:keychain:scopes:)``
 for initialization examples.
 */
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
open class PKCEAuthorizationFlow: Swauthable {
    // MARK: - Properties
    /// An instance of PKCE
    lazy var pkce = PKCE()
    /// The PKCE code verifier string.
    ///
    /// The code verifier is a random 128 character string.
    var codeVerifier: String {
        pkce.codeVerifier
    }
    /// The PKCE code challenge string.
    ///
    /// The code challenge string is a Base64-URL encoded string of the
    /// SHA256 hash of the code verifier.
    var codeChallenge: String {
        pkce.codeChallenge
    }

    /// The client identifier issued by the server. Is initialzed.
    public let clientID: String

    /// Instance of KeychainAccess. Is initialized.
    public let keychain: Keychain

    /// The application's redirect URI. Is initialized.
    public let redirectURI: String

    /// The scopes you want your app to be authorized for, separated by spaces.
    open var scopes: String?

    let state: String

    /// The server authorization endpoint URL. Is initialized.
    public let authorizationEndpoint: URL
    /// The parameters for the ``authorizationURL``. Read-only.
    ///
    /// Not including ``scopes`` and ``additionalAuthorizationParams``, this property is:
    /// ```swift
    /// [
    ///     "response_type": "code",
    ///     "client_id": clientID,
    ///     "state": state,
    ///     "redirect_uri": redirectURI,
    ///     "code_challenge": codeChallenge,
    ///     "code_challenge_method": "S256"
    /// ]
    /// ```
    open var authorizationParams: [String: String] {
        var authURLParams = [
            "response_type": "code",
            "client_id": clientID,
            "state": state,
            "redirect_uri": redirectURI,
            "code_challenge": codeChallenge,
            "code_challenge_method": "S256"
        ]
        if scopes != nil { authURLParams.merge(with: ["scope": scopes!]) }
        if additionalAuthorizationParams != nil {
            authURLParams.merge(with: additionalAuthorizationParams!)
        }
        return authURLParams
    }
    /// Additional authorization parameters.
    ///
    /// See ``authorizationParams`` for the provided parameters.
    public var additionalAuthorizationParams: [String: String]?
    /// A URL constructed from the ``authorizationEndpoint`` and ``authorizationParams`` for use with an
    /// ASWebAuthenticationSession. Read-only.
    open var authorizationURL: URL {
        return authorizationEndpoint.addQueryItems(authorizationParams)
    }

    /// The server's token endpoint URL. Is initialized.
    public let tokenEndpoint: URL
    /// The HTTP body parameters for the token request. Read-only.
    ///
    /// The key/value pair for "code" is handled by the ``authorizationResponseHandler(for:)``
    /// method.
    ///
    /// Other than the key/value pair for "code" this property is:
    /// ```swift
    /// [
    ///     "grant_type": "authorization_code",
    ///     "redirect_uri": redirectURI,
    ///     "client_id": clientID,
    ///     "code_verifier": codeVerifier
    /// ]
    /// ```
    open var tokenRequestParams: [String: String] {
        [
            "grant_type": "authorization_code",
            "redirect_uri": redirectURI,
            "client_id": clientID,
            "code_verifier": codeVerifier
        ]
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

    /// Some servers may use a different key for their authorization header's token type than the one
    /// provided by the token request response.
    ///
    /// For example, Github uses "token", however their token response type is "bearer".
    open var authHeaderTokenType: String?

    // MARK: - Methods
    /// Handles the callback URL from an ASWebAuthenticationSession
    /// and sends a HTTP request to the initalized token endpoint for the tokens.
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
        request.httpBody = httpBody

        try await tokenRequest(request: request)
    }
    
    // MARK: - Structs
    // Most of the code in this struct is derivative of:
    // https://bootstragram.com/blog/oauth-pkce-swift-secure-code-verifiers-and-code-challenges/
    /// Tthe proof keys for the Proof Key for Code Exchange (PKCE) extension to the OAuth 2.0
    /// Authorization Code Flow according to RFC 7636.
    internal struct PKCE {
        let codeVerifier: String
        let codeChallenge: String

        static func base64URLEncode<S>(_ bytes: S) -> String where S: Sequence, UInt8 == S.Element {
            let data = Data(bytes)
            return data
                .base64EncodedString() // Regular base64 encoder
                .replacingOccurrences(of: "=", with: "") // Remove any trailing '='s
                .replacingOccurrences(of: "+", with: "-") // 62nd char of encoding
                .replacingOccurrences(of: "/", with: "_") // 63rd char of encoding
                .trimmingCharacters(in: .whitespaces)
        }

        static func random128CharacterString() -> String {
            var bytes = [UInt8](repeating: 0, count: 96)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            if status == errSecSuccess {
                return PKCE.base64URLEncode(bytes)
            } else {
                return String.random(ofLength: 128)
            }
        }

        init() {
            let verifier = PKCE.random128CharacterString()
            self.codeVerifier = verifier
            let challenge = verifier
                .data(using: .utf8)
                .map { SHA256.hash(data: $0) }
                .map { PKCE.base64URLEncode($0) }
            self.codeChallenge = challenge!
        }
    }


    // MARK: - Initializers
    /**
     Initializes a PKCEAuthorizationFlow object.
     
     This initializer is called by
     ``init(clientID:authorizationEndpoint:tokenEndpoint:redirectURI:keychain:scopes:)``.
     
     Example Code:
     ```swift
     // the "accessGroup" parameter is only necessary if you wish to share the keychain accross
     // multiple targets using a keychain sharing entitlement
     let keychain = Keychain(service: "your.app.bundleID", accessGroup: "appIdentifierPrefix.your.app.bundleID")
        .label("Your App Name")
     
     let domain = PKCEAuthorizationFlow(
        clientID: "9d73bfb50b304543b35f41d427e6b76c",
        authorizationEndpoint: URL(string: "https://domain.com/authorize")!,
        tokenEndpoint: URL(string: "https://domain.com/token")!,
        redirectURI: "appname://callback",
        keychain: keychain
     )
     ```
     
     - Parameters:
        - clientID: The client identifier issued by the server.
        -  authorizationEndpoint: The server authorization endpoint URL.
        -  tokenEndpoint: The server token endpoint URL.
        - redirectURI: Your application's redirect URI.
        - Keychain: An instance of Keychain from KeychainAccess.
        [Full KeychainAccess
         documentation](https://github.com/kishikawakatsumi/KeychainAccess).
     */
    public init(clientID: String,
                authorizationEndpoint: URL,
                tokenEndpoint: URL,
                redirectURI: String,
                keychain: Keychain) {
        self.clientID = clientID
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.redirectURI = redirectURI
        self.keychain = keychain

        self.state = String.random(ofLength: 8)
    }
    /**
     Initializes a PKCEAuthorizationFlow object, with scopes.
     
     This initializer calls
     ``PKCEAuthorizationFlow/init(clientID:authorizationEndpoint:tokenEndpoint:redirectURI:keychain:)``,
     and initiializes the scopes property.
     
     Example Code:
     ```swift
     // the "accessGroup" parameter is only necessary if you wish to share the keychain accross
     // multiple targets using a keychain sharing entitlement
     let keychain = Keychain(service: "your.app.bundleID", accessGroup: "appIdentifierPrefix.your.app.bundleID")
        .label("Your App Name")
     
     let domain = PKCEAuthorizationFlow(
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
        - redirectURI: Your application's redirect URI.
        - Keychain: An instance of Keychain from KeychainAccess.
        [Full KeychainAccess
         documentation](https://github.com/kishikawakatsumi/KeychainAccess).
        - scopes: The scopes you want your app to be authorized for, separated by spaces.
     */
    public convenience init(clientID: String,
                            authorizationEndpoint: URL,
                            tokenEndpoint: URL,
                            redirectURI: String,
                            keychain: Keychain,
                            scopes: String) {
        self.init(clientID: clientID,
                  authorizationEndpoint: authorizationEndpoint,
                  tokenEndpoint: tokenEndpoint,
                  redirectURI: redirectURI,
                  keychain: keychain)
        self.scopes = scopes
    }
}
