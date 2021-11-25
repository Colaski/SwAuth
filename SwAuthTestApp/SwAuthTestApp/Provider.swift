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

// This app uses the MVVM (Model-View-ViewModel) pattern to expose the Spotify API. Instances of
// the Spotify class provided by SwAuth can be used as a Model. The classes ProviderStore
// and Provider are ViewModels, modeling the Views ProvidersView and ProviderView respectively.

import Foundation
import SwAuth

// MARK: - Spotify Extensions
// I can add to my Model by extending the Spotify class. Now every instance has these properties.
extension Spotify {
    /// A  request stored in UserDefaults using the instance's client ID and the string "storedReq" separated by a colon
    /// as the key.
    var storedRequest: String? {
        return UserDefaults.standard.string(forKey: clientID + ":storedReq")
    }
    /// The scheme of the redirect URI.
    var redirectURIScheme: String {
        return URL(string: redirectURI)!.scheme!
    }
}

// MARK: - ProviderStore
/**
 ProviderStore pretty much just contains an array of Providers. For each Provider in the array, ProvidersView will display a NavigationLink destined for a ProviderView.
 */
struct ProviderStore {
    private static let keychain = Keychain(service: "com.colaski.SwAuthTestApp")
        .label("SwAuthTestApp")
    
    private static let spotify = Spotify(
        clientID: "41529aff1ed145c793767ec797005f59",
        redirectURI: "swauthtest://callback",
        keychain: keychain,
        // Don't need scopes since this demo will not access protected information.
        scopes: ""
    )
    private static let spotify2 = Spotify(
        clientID: "62afe8ecc21a4fa0a40fe1e93d3798c9",
        redirectURI: "swauthtest2://callback",
        keychain: keychain,
        scopes: ""
    )
    
    static let providers = [
        Provider(spotify, label: "Account 1"),
        Provider(spotify2, label: "Account 2")
    ]
}

// MARK: - Provider
/**
 If the instance of Spotify has not been authenticated, ProviderView displays an Authenticate button that starts an ASWebAuthenticationSession. Otherwise, a button that sends an HTTP request will be displayed.
 */
class Provider: ObservableObject, Identifiable {
    // MARK: Properties
    /// The instance's client id.
    let id: String
    
    let label: String
    
    /// An instance of spotify.
    var provider: Spotify
    
    /// The redirect URI's scheme.
    let redirectURIScheme: String
    
    /// A URL constructed from the authroizaion endpoint for use with an ASWebAuthenticationSession.
    var authorizationURL: URL
    
    /// The instance's isAuthorized property.
    @Published var isAuthed: Bool
    
    /// The instance's storedRequest property.
    @Published var storedRequest: String?
    /// Stores a request in UserDefaults using the id and the string "storedReq" separated by a colon as the key and updates
    /// the storedRequest variable.
    func storeStoredRequest(_ store: String) {
        UserDefaults.standard.set(store, forKey: id + ":storedReq")
        storedRequest = store
    }
    
    // MARK: Methods
    func request() async throws -> String {
        /*
         The Spotify class in SwAuth contains a wrapped authorizedRequest
         for the Spotify web API's Get All New Releases endpoint.
         */
        let response = try await provider.getAllNewReleases(
            country: nil,
            limit: "1",
            offset: nil
        )
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d h:mm a"
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        let date = dateFormatter.string(from: Date())
        
        /*
         Since the response is SwiftyJSON, you can get a
         value for a key using a path like this. Check out
         the SwiftyJSON documentation for more ways:
         https://github.com/SwiftyJSON/SwiftyJSON
         */
        let albumName = response["albums", "items", 0, "name"]
        let artist = response["albums", "items", 0, "artists", 0, "name"]
        
        return """
                Spotify is featuring the album \(albumName) by \(artist)
                        
                Request made \(date):\n\(response)
                """
    }
    
    /// A property whose type is the signature of the Swauthable authorizationResponseHandler method.
    ///
    /// The value of this property is initialized as the Spotify instance's authorizationResponseHandler
    /// method. Thus, accessing this property will call the Spotify instance's authorizationResponseHandler
    /// method.
    private let authResHand: (URL) async throws -> Void
    /// Handles the callback URL from an ASWebAuthenticationSession
    /// and sends a HTTP request for token. Tokens are saved to the Keychain instance.
    ///
    /// - Note: Calls the instance's tokenRequest method, see its docemntation for
    /// more deatils
    ///
    /// - Parameter url: The callback URL from a ASWebAuthenticationSession.
    func authorizationResponseHandler(url: URL) async throws {
        /*
         Since the value of the authResHand property is initialized as the Spotify
         instance's authorizationResponseHandler method, calling a Provider instance's
         authorizationResponseHandler method just calls the Spotify instance's method.
         */
        try await authResHand(url)
    }
    
    // MARK: Initializer
    /**
     Initializes a Provider object.
     
     - Parameters:
        - \_:  An instance of Spotify.
        - label: A label. Should be the name of the API. Is the ProvidersView NavigationLink label,
        and the ProviderView navigation bar title.
     */
    init(_ provider: Spotify, label: String) {
        self.id = provider.clientID
        self.label = label
        self.provider = provider
        self.isAuthed = provider.isAuthorized
        self.storedRequest = provider.storedRequest
        self.redirectURIScheme = provider.redirectURIScheme
        self.authorizationURL = provider.authorizationURL
        
        self.authResHand = provider.authorizationResponseHandler
    }
}
