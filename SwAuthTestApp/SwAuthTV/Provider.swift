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

import UIKit
import SwAuth
import SwiftUI

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
class Provider: ObservableObject {
    static let keychain = Keychain(service: "com.colaski.SwAuthTV")
        .label("SwAuthTV")
    static let provider = GoogleTVDevice(
        clientID: "672294251230-5gmg9an4g9bh39bk5gs68ae9dihsh8i1.apps.googleusercontent.com",
        clientSecret: "oLvFJoJBckihnv0UEevFWU6s",
        keychain: keychain,
        scopes: "email profile")
    
    @Published var isAuthed: Bool
    
    @Published var authResponse = DeviceAuthorizationFlow.DeviceFlowAuthResponse?(nil)
    
    var verification: (uri: String?, userCode: String?) {
        (authResponse?.verificationURI, authResponse?.userCode)
    }
    var qrCode: Image? {
        if authResponse != nil {
            let uiImage = authResponse!.qrCode != nil ? UIImage(cgImage: authResponse!.qrCode!) : nil
            return uiImage != nil ? Image(uiImage: uiImage!) : nil
        } else {
            return nil
        }
    }
    
    private var _startPollingToken: (Response) async throws -> Void
    func startPollingToken() async throws {
        try await _startPollingToken(authResponse!)
    }
    
    private var _deviceFlowAuthorizationRequest: () async throws -> DeviceAuthorizationFlow.DeviceFlowAuthResponse
    func deviceFlowAuthorizationRequest() async throws -> DeviceAuthorizationFlow.DeviceFlowAuthResponse {
        try await _deviceFlowAuthorizationRequest()
    }
    
    init() {
        self.isAuthed = Provider.provider.isAuthorized
        
        self._deviceFlowAuthorizationRequest = Provider.provider.deviceFlowAuthorizationRequest
        self._startPollingToken = Provider.provider.authorizationResponseHandler
    }
}
