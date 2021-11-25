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

import SwiftUI
import SwAuth
import BetterSafariView

struct ProviderView: View {
    @ObservedObject var provider: Provider
    @State private var alert = (isShowing: false, alertMessage: "")
    
    var body: some View {
        Group{
            if provider.isAuthed {
                authorizedView(provider: provider, alert: $alert)
            } else {
                authorizationView(provider: provider, alert: $alert)
            }
        }
        .navigationBarTitle(provider.label, displayMode: .inline)
        .alert(isPresented: $alert.0) {
            Alert(title: Text("Error"),
                  message: Text(alert.1),
                  dismissButton: .default(Text("OK")))
        }
    }
}

/// A view containing a button that sends an authorized request and displays a stored request, if one exists.
struct authorizedView: View {
    @ObservedObject var provider: Provider
    @Binding var alert: (isShowing: Bool, alertMessage: String)
    
    var body: some View {
        Button("""
               Send Request to the Spotify Web API's
               Get All New Releases endpoint
               """) {
            /*
             Within a Task.init closure, an operation is
             treated like an asynchronous extension to a
             synchronous operation. Thus, asynchronous calls
             can be made when asynchronous function types
             aren't supported, like in SwiftUI views.
             */
            Task.init {
                do {
                    let storeRequest = try await provider.request()
                    // Stores the request response.
                    provider.storeStoredRequest(storeRequest)
                } catch {
                    /*
                     If any errors were thrown in the do block, an
                     alert showing the error will be presented.
                     */
                    self.alert = (true, error.localizedDescription)
                }
            }
        }
        .padding()
        .background(Color.accentColor)
        .foregroundColor(Color.white)
        .cornerRadius(30)
        // Displays a stored request, if one exists.
        if provider.storedRequest != nil {
            GroupBox {
                ScrollView {
                    Text(provider.storedRequest!)
                }
            }.padding()
        }
        Spacer()
    }
}

/// A view containg a button that starts an ASWebAuthenticationSession.
struct authorizationView: View {
    @ObservedObject var provider: Provider
    @Binding var alert: (isShowing: Bool, alertMessage: String)
    @State private var startingWebAuthenticationSession = false
    
    var body: some View {
        Button("Authorize") {
            /*
             Starts an ASWebAuthenticationSession using
             BetterSafariView.
             https://github.com/stleamist/BetterSafariView
             */
            self.startingWebAuthenticationSession = true
        }
        .webAuthenticationSession(isPresented: $startingWebAuthenticationSession) {
            WebAuthenticationSession(
                url: provider.authorizationURL,
                /*
                 The expetced scheme of the callback URL (the scheme
                 of the redirectURI)
                 */
                callbackURLScheme: provider.redirectURIScheme
            ) { callbackURI, error in
                /*
                 Within a Task.init closure, an operation is
                 treated like an asynchronous extension to a
                 synchronous operation.
                 */
                Task.init {
                    do {
                        guard error == nil else { throw error! }

                        /*
                         Handles the callback URL from the
                         ASWebAuthenticationSession and sends
                         a HTTP request for the authentication
                         token. The resulting Tokens are saved
                         to the instance's Keychain.
                         */
                        try await provider.authorizationResponseHandler(url: callbackURI!)
                        // This provider is now authorized, an
                        // authorizedView will be presented instead.
                        self.provider.isAuthed = true
                    } catch {
                        /*
                         If any errors were thrown in the do block, an
                         alert showing the error will be presented.
                         */
                        self.alert = (true, error.localizedDescription)
                    }
                }
            }
        }
    }
}
