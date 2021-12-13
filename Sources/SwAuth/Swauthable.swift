//
// Swauthable.swift
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
import AsyncHTTPClient
@_exported import KeychainAccess
@_exported import enum NIOHTTP1.HTTPMethod

/// All of the authorization flows (``AuthorizationCodeFlow``, ``PKCEAuthorizationFlow``,
///  ``DeviceAuthorizationFlow``) conform to this protocol.
///
/// Swauthable provides some default implementations.
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public protocol Swauthable {
    // MARK: - Properties
    /// The client identifier issued by the server. Is initialized.
    var clientID: String { get }

    /// Instance of KeychainAccess. Is initialized.
    var keychain: Keychain { get }

    /// The scopes you want your app to be authorized for, separated by spaces.
    var scopes: String? { get }

    /// The server authorization endpoint URL. Is initialized.
    var authorizationEndpoint: URL { get }

    var authorizationParams: [String: String] { get }
    /// Additional a authorization parameters.
    ///
    /// See `authorizationParams` for the provided parameters.
    var additionalAuthorizationParams: [String: String]? { get }

    /// The server's token endpoint URL. Is initialized.
    var tokenEndpoint: URL { get }
    /// The HTTP body parameters for the token request.
    var tokenRequestParams: [String: String] { get }
    /// Any additional parameters for the token request.
    ///
    /// See `tokenRequestParams` for the provided parameters.
    var additionalTokenRequestParams: [String: String]? { get }
    /// **Ignore if the server not provide a refresh token.**
    /// Any additional HTTP body parameters for the token refresh request. The key/value pairs for
    /// "refresh\_token" and "grant\_type" are handled internally when an
    /// ``authenticatedRequest(for:numberOfRetries:)``
    /// is made.
    var additionalRefreshTokenBodyParams: [String: String]? { get }

    /// Some APIs may use a different key for their authorization header's token type than the one
    /// provided by the token request response.
    ///
    /// For example, Github uses "token", however their token response type is "bearer".
    var authHeaderTokenType: String? { get }

    // MARK: - Methods
    /**
     Handles a ``Response``. Sends a HTTP request to the initialized token endpoint for the tokens.
     
     Tokens are saved to the Keychain instance provided by the initializer. The tokens are saved using
     the instance's client id and the string "tokens" separated by a colon as the key. For example:
     "9d73bfb50b304543b35f41d427e6b76c:tokens"
     
     If an HTTP error occurs, the token request will be retried once.
     
     - Parameter for: A ``Response``.
     */
    func authorizationResponseHandler(for: Response) async throws
}

// MARK: - Default Implementations
// These are default implementations for every instance that conforms to Swauthable.
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
extension Swauthable {
    // MARK: - Property
    /// True if the keychain instance contains tokens from a token request. If your application has been authorized by
    /// the user, will return true. Read-only.
    ///
    /// This property will only be true if the instance's ``authorizationResponseHandler(for:)``
    /// method has been called.
    public var isAuthorized: Bool {
        return keychain[data: "\(clientID):tokens"] != nil ? true : false
    }

    // MARK: - Methods
    /**
     Sends a HTTP request to the token endpoint and saves the tokens from the response to keychain.
     
     This method is called by the instance's ``Swauthable/authorizationResponseHandler(for:)``
     and ``authorizationResponseHandler(for:)`` when tokens need to be refreshed.
     
     If an HTTP error occurs, the token request will be retried once.
     
     - Parameters:
        - request: An instance of ``HTTPRequest``.
     */
    @discardableResult
    func tokenRequest(request: HTTPRequest) async throws -> Tokens {
        var loop = (success: false, retries: UInt8(0))
        repeat {
            do {
                let response = try await http(request: request).json()
                let tokens = try Tokens(fromJSON: response)
                try tokens.saveTokens(for: clientID, in: keychain)
                loop.0 = true
                return tokens
            } catch {
                if loop.1 < 1 {
                    loop.1 += 1
                    continue
                } else {
                    throw error
                }
            }
        } while loop.0 == false
    }
    /// **Used Internally**, refresh tokens are handled internally by the library.
    ///
    /// Called by the instance's ``authenticatedRequest(for:numberOfRetries:)`` method.
    /// Checks if the instance has a refresh token. If it does, and the access token is expired, calls the
    /// `refreshToken` method.
    public func checkRefreshToken(tokens: inout Tokens) async throws {
        if tokens.isRefreshable {
            if let accessTokenCreationDate = keychain[attributes: "\(clientID):tokens"]?.creationDate {
                if NSDate().timeIntervalSince(accessTokenCreationDate) >= Double(tokens.tokenExpiration - 30) {
                    try await refreshToken(tokens: &tokens)
                }
            }
        }
    }
    /// **Ignore if the Web API does not provide a refresh token.**
    /// This method is called by the instance's `checkRefreshToken` method when the access token
    /// has expired.
    ///
    /// Sends a HTTP request to the token endpoint by calling the `tokenRequest` method.
    func refreshToken(tokens: inout Tokens) async throws {
        guard tokens.refreshToken != "null" else {
            throw SwAuthError.authorizationFailure(reason: .noRefreshToken)
        }
        var body = ["refresh_token": tokens.refreshToken, "grant_type": "refresh_token"]
        if additionalRefreshTokenBodyParams != nil {
            body.merge(with: additionalRefreshTokenBodyParams!)
        }

        lazy var request = HTTPRequest(endpoint: tokenEndpoint)
        request.httpMethod = .POST
        request.httpBody = body

        // AuthorizationCodeFlow is the only flow that has "client_secret" in the
        // token params and will never have it in the additional token params.
        if let secret = tokenRequestParams["client_secret"],
            additionalTokenRequestParams?["client_secret"] == nil {
            let stringData = "\(clientID):\(secret)".data(using: .utf8)
            let base64 = stringData!.base64EncodedString()
            request.additionalHTTPHeaders = ["Authorization": "Basic \(base64)"] // 😈
        }
        tokens = try await tokenRequest(request: request)
    }

    /**
     Sends an authenticated HTTP request to a Web API endpoint. Returns a ``HTTPRequest/Response``.

     When this method is called, the keychain instance is checked for a refresh token. If the keychain instance
     does contain a refresh token, the access token is checked for being expired. The initial refresh token (if
     there is one), and the length of time until the access token expiries (if it has an expiration), are provided
     by the token request made when the ``authorizationResponseHandler(for:)`` is called. If
     the access token has expired, an HTTP request is made to the ``tokenEndpoint``,
     requesting a new access token and refresh token using the current refresh token.

     - Note: The HTTP request may occasionally fail. It is recommend to retry at least once.
     
     - Parameter for: A ``HTTPRequest`` instance.
     - Parameter numberOfRetries: How many times the request should be retried in the event of an error.
     Default is 0.
     */
    public func authenticatedRequest(
        for request: HTTPRequest,
        numberOfRetries: UInt8 = 0
    ) async throws -> HTTPRequest.Response {
        var httpRequest = request
        var tokens = try Tokens(for: clientID, from: keychain)

        var loop = (response: HTTPRequest.Response?(nil), retries: UInt8(0))
        repeat {
            do {
                try await checkRefreshToken(tokens: &tokens)

                let authHeader = [
                    "Authorization": "\(authHeaderTokenType ?? tokens.tokenType) \(tokens.accessToken)"
                ]
                if httpRequest.additionalHTTPHeaders != nil {
                    httpRequest.additionalHTTPHeaders!.merge(with: authHeader)
                } else {
                    httpRequest.additionalHTTPHeaders = authHeader
                }

                let response = try await http(request: httpRequest)
                loop.response = response
            } catch {
                if loop.retries < numberOfRetries {
                    loop.retries += 1
                    continue
                } else {
                    throw error
                }
            }
        } while loop.response == nil
        return loop.response!
    }
}
