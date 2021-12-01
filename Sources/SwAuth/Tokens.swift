//
// Tokens.swift
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

/// The tokens from a token request.
///
/// Conforms to `Codable`.
public struct Tokens: Codable {
    // MARK: - Properties
    /// The access token.
    public let accessToken: String
    /// The type of access token, RFC 6750 defines Bearer as a token type. Defaults to "Bearer".
    public let tokenType: String
    /// A refresh token provided by the token request. Is "null" when one is not provided.
    public let refreshToken: String
    /// How long the access token is valid before it must be refreshed. Assumes time is in seconds. Defaults to
    /// 3600 (1 hour).
    public let tokenExpiration: Int
    /// True if the refresh token isn't "null".
    public var isRefreshable: Bool {
        return refreshToken == "null" ? false : true
    }

    // MARK: - Methods
    /// Encodes an instance of Tokens. Returns JSON data.
    public func encode() throws -> Data {
        lazy var encoder = JSONEncoder()
        do {
            return try encoder.encode(self)
        } catch {
            throw SwAuthError.systemError(error: error)
        }
    }

    /**
     Saves an instance of Tokens to an instance of keychain using a client id or other unique string plus the
     string "tokens" separated by a colon as the key.
     
     - Parameters:
        - for: A client id or other unique string.
        - in: An instance of keychain.
     */
    public func saveTokens(for clientID: String, in keychain: Keychain) throws {
        keychain[data: "\(clientID):tokens"] = try self.encode()
    }

    // MARK: - Inits
    /// Decodes data into an instance of Tokens.
    ///
    /// - Parameter fromData: An instance of Tokens that was encoded into JSON data by its
    /// ``encode()`` method.
    public init(fromData: Data) throws {
        let decoder = JSONDecoder()
        do {
            self = try decoder.decode(Tokens.self, from: fromData)
        } catch {
            throw SwAuthError.systemError(error: error)
        }
    }
    /**
     Fetches an instance of Tokens that was previously saved to a keychain instance by the
     ``saveTokens(for:in:)`` method.
     
     - Parameters:
        - for: A client id or other unique string. MUST be the same one used to save the tokens.
        - from: An instance of keychain. MUST be the same one used to save the tokens.
     */
    public init(for clientID: String, from keychain: Keychain) throws {
        guard let tokenData = keychain[data: "\(clientID):tokens"] else {
            throw SwAuthError.authorizationFailure(reason: .noAccessToken)
        }
        self = try Tokens(fromData: tokenData)
    }

    private init(accessToken: String,
                 tokenType: String,
                 refreshToken: String,
                 tokenExpiration: Int) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.refreshToken = refreshToken
        self.tokenExpiration = tokenExpiration
    }
    /// Converts JSON from a token request into a Tokens instance.
    ///
    /// - Parameter fromJSON: A  SwiftyJSON instance of the response from a token request.
    internal init(fromJSON: JSON) throws {
        guard let accessToken = fromJSON["access_token"].string else {
            throw SwAuthError.authorizationFailure(reason: .accessTokenInvalid)
        }
        let tokenType = fromJSON["token_type"].string ?? "Bearer"

        var refreshToken = "null"
        if fromJSON["refresh_token"].exists() {
            guard let refreshTokenString = fromJSON["refresh_token"].string else {
                throw SwAuthError.authorizationFailure(reason: .refreshTokenInvalidType)
            }
            refreshToken = refreshTokenString
        }

        let refreshTokenExpiration = fromJSON["expires_in"].int ?? 3600

        self.accessToken = accessToken
        self.tokenType = tokenType
        self.refreshToken = refreshToken
        self.tokenExpiration = refreshTokenExpiration
    }
}
