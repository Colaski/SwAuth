//
// Globals.swift
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
import NIO

internal typealias Request = HTTPClient.Request
fileprivate let httpClient = HTTPClient(
    eventLoopGroupProvider: .createNew,
    configuration: HTTPClient.Configuration(timeout: .init(connect: .seconds(5)))
)

/// Sends a HTTP request. Returns a ``HTTPRequest/Response`` instance.
///
/// - Parameter request: A ``HTTPRequest`` instance.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
internal func http(request: HTTPRequest) async throws -> HTTPRequest.Response {
    let httpRequest = try Request(from: request)
    var deadline: NIODeadline? {
        return request.timeoutAfter != nil ? .now() + request.timeoutAfter! : nil
    }

    return try await withCheckedThrowingContinuation { continuation in
        httpClient.execute(request: httpRequest, deadline: deadline).whenComplete { result in
            switch result {
            case .failure(let error):
                continuation.resume(throwing: SwAuthError.systemError(error: error))
            case .success(var response):
                let dataLength = response.body!.readableBytes
                let data = response.body!.readData(length: dataLength)!
                if response.status == .ok {
                    continuation.resume(returning: HTTPRequest.Response(data: data))
                } else {
                    continuation.resume(throwing: SwAuthError.httpError(json: data.jsonString ?? "\(response.status)" as NSString))
                }
            }
        }
    }
}
