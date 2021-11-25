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

struct ContentView: View {
    @ObservedObject var provider = Provider()
    @State var userInfo = String?(nil)
    @State private var alert = (isShowing: false, alertMessage: "")

    var body: some View {
        Group {
            if provider.isAuthed {
                Text("Authroized!")
                Button("Send request") {
                    Task.init {
                        do {
                            let request = HTTPRequest(endpoint: URL(string: "https://openidconnect.googleapis.com/v1/userinfo")!)
                            let json = try await Provider.provider.authenticatedRequest(for: request).json()
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MMM d h:mm a"
                            dateFormatter.timeZone = TimeZone(abbreviation: "PST")
                            let date = dateFormatter.string(from: Date())
                            userInfo = """
                                        Request made on \(date):
                                        
                                        \(json)
                                        """
                        } catch {
                            alert = (true, error.localizedDescription)
                        }
                    }
                }
                if userInfo != nil {
                    Text(userInfo!)
                }
            } else {
                if provider.authResponse == nil {
                    Button("Authorize") {
                        Task.init {
                            do {
                                let authResponse = try await provider.deviceFlowAuthorizationRequest()
                                provider.authResponse = authResponse
                            } catch {
                                alert = (true, error.localizedDescription)
                            }
                            
                        }
                    }
                } else {
                    Text(provider.verification.uri!)
                    Text(provider.verification.userCode!)
                        .onAppear {
                            Task.init {
                                do {
                                    try await provider.startPollingToken()
                                    self.provider.isAuthed = true
                                } catch {
                                    alert = (true, error.localizedDescription)
                                }
                            }
                        }
                    provider.qrCode
                }
            }
        }.alert(isPresented: $alert.0) {
            Alert(title: Text("Error"),
                  message: Text(alert.1),
                  dismissButton: .default(Text("OK")))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
