//
// Response.swift
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

/// A response to be handled by a ``Swauthable/authorizationResponseHandler(for:)``.
///
/// A response is either a URL from an ASWebAuthenticationSession or a
/// ``DeviceAuthorizationFlow/DeviceAuthResponse``
/// returned from the ``DeviceAuthorizationFlow/deviceFlowAuthorizationRequest()`` method.
///
/// Foundation's URL and ``DeviceAuthorizationFlow/DeviceAuthResponse`` conform
/// to this type.
public protocol Response {}

extension URL: Response {}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension DeviceAuthorizationFlow.DeviceAuthResponse: Response {}
