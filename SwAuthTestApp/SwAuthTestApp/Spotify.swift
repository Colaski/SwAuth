//
// File.swift
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
import SwAuth

/// A class representing the Spotify web API. Uses the PKCE Authorization Code Flow for authentication.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public class Spotify: PKCEAuthorizationFlow {
    // MARK: - Init
    /**
     Initializes an instance of Spotify.

     - Parameters:
       - clientID: The client id of your created application. An application can be created at your
       [Spotify developer dashboard](https://developer.spotify.com/dashboard/applications).
       - redirectURI: Your application's redirect URI. This parameter must be identical to the redirect URI you
       input in the settings of your dashboard.
       - Keychain: An instance of Keychain from KeychainAccess. Here is an example (the "accessGroup"
       parameter is only necessary if you wish to share the keychain accross multiple targets using a keychain
       sharing entitlement):

             let keychain = Keychain(service: "com.your.bundleID", accessGroup: "appIdentifierPrefix.com.your.bundleID")
                 .label("Your App Name")
           [Full KeychainAccess
            documentation](https://github.com/kishikawakatsumi/KeychainAccess).
       - scopes: A space-separated string of scopes you want your application to be authorized for. Scopes
       provide Spotify users using third-party apps the confidence that only the information they choose to share
       will be shared, and nothing more. A full list of scopes can be found in the
       [developer documentation](https://developer.spotify.com/documentation/general/guides/scopes).
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

    // MARK: -
    // MARK: Get All New Releases Endpoint
    /**
     Makes an authorized request to the "Get All New Releases" endpoint. Returms SwiftyJSON.
     https://github.com/SwiftyJSON/SwiftyJSON
     
     [Spotify Web API Reference, Browse
     Category](https://developer.spotify.com/documentation/web-api/reference/#category-browse)
     
     Required scopes:
     
     None are required for this endpoint.
     
     - Parameters:
        - country: A country: an [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)
        country code. Provide this parameter if you want the list of returned items to be relevant to a particular
        country. If omitted,
        the returned items will be relevant to all countries. Use nil to omit.
        - limit: The maximum number of items to return. Default: 20. Minimum: 1. Maximum: 50. Use nil for
        default.
        - offset: The index of the first item to return. Default: 0 (the first object). Use with limit to get the next
        set of items. Use nil for default.
        - numberOfRetries: How many times the request should be retried in the event of an error.
        Default is 0.
     */
    public func getAllNewReleases(
        country: String? = nil,
        limit: String? = nil,
        offset: String? = nil,
        numberOfRetries: UInt8 = 0
    ) async throws -> JSON {
        var request = HTTPRequest(
            endpoint: URL(string: "https://api.spotify.com/v1/browse/new-releases")!
        )
        var query = [String: String]()
        if country != nil { query.merge(with: ["country": country!]) }
        if limit != nil { query.merge(with: ["limit": limit!]) }
        if offset != nil { query.merge(with: ["offset": offset!]) }
        if query.isEmpty == false {
            request.endpointQueryItems = query
        }

        return try await self.authenticatedRequest(
            for: request,
            numberOfRetries: numberOfRetries
        ).json()
    }
}

internal extension Dictionary {
    /// Merges the dictionary with another.
    ///
    /// - Parameter with: The dictionary to be merged.
    mutating func merge(with: Dictionary) {
        with.forEach { self[$0] = $1 }
    }
}
