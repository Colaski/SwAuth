//
// Spotify.swift
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

/// Spotify's Web API.
///
/// [Spotify reference documentation](https://developer.spotify.com/documentation/web-api/reference/#/)
///
/// Inherits from ``PKCEAuthorizationFlow``.
///
/// See ``init(clientID:redirectURI:keychain:scopes:)``  for initialization.
public final class Spotify: PKCEAuthorizationFlow {
  // MARK: - Init
    /**
     Initializes an instance of Spotify.

     - Parameters:
       - clientID: The client id of your created application. An application can be created at your
       [Spotify developer dashboard](https://developer.spotify.com/dashboard/applications).
       - redirectURI: Your application's redirect URI. This parameter must be identical to the redirect URI you
       input in the settings of your dashboard.
       - Keychain: An instance of Keychain from KeychainAccess. Here is an example (the "accessGroup"
       parameter is only necessary if you wish to share the keychain across multiple targets using a keychain
       sharing entitlement):

             let keychain = Keychain(service: "com.your.bundleID", accessGroup: "appIdentifierPrefix.com.your.bundleID")
                 .label("Your App Name")
           [Full KeychainAccess
            documentation](https://github.com/kishikawakatsumi/KeychainAccess).
       - scopes: A space-separated string of scopes you want your application to be authorized for. Each endpoint has a
       required
     */
    public convenience init(clientID: String,
                            redirectURI: String,
                            keychain: Keychain,
                            scopes: String) {
        self.init(
            clientID: clientID,
            authorizationEndpoint: URL(string: "https://accounts.spotify.com/authorize")!,
            tokenEndpoint: URL(string: "https://accounts.spotify.com/api/token")!,
            redirectURI: redirectURI,
            keychain: keychain,
            scopes: scopes
        )
        self.additionalRefreshTokenBodyParams = ["client_id": clientID]
    }
}
