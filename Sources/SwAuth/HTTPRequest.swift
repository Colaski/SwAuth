//
// HTTPRequest.swift
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
import NIOHTTP1
@_exported import struct NIO.TimeAmount

/**
HTTP load request.
 
 - Note: The ``httpMethod`` defaults to GET.
 */
public struct HTTPRequest {
    // MARK: - Properties
    /// The server endpoint URL to which the HTTP request will be sent. Is initialized.
    public let endpoint: URL
    /// Query items to add to the endpoint URL.
    public var endpointQueryItems: [String: String]?

    /// The endpoint with the queryItems, returns the endpoint if queryItems is nil.
    internal var queriedEndpoint: URL {
        return endpointQueryItems == nil ? endpoint : endpoint.addQueryItems(endpointQueryItems!)
    }

    /// The HTTPMethod of the request, default is GET.
    public var httpMethod = HTTPMethod.GET

    /// The body of the HTTP request.
    ///
    /// The body will be encoded as application/x-www-form-urlencoded by default. See the ``bodyEncoding``
    /// property to specify an encoding for the body.
    public var httpBody: [String: Any]?
    /// The ``RequestBodyEncoding`` of the body being sent. Defaults to ``RequestBodyEncoding/FORM``.
    public var bodyEncoding: RequestBodyEncoding = .FORM

    /// Any additional HTTP header values besides "Authentication" and "Content-Type".
    public var additionalHTTPHeaders: [String: String]?
    
    /// Set the amount of time allowed for the request to complete before it times out.
    ///
    /// By default, all requests are set to automatically timeout after 5 seconds of attempting to connect. Setting this property
    /// will void that default behavior. If the request has not been completed after the amount of time set by this property, it
    /// will terminate.
    ///
    /// Suppports nanoseconds, microseconds, milliseconds, seconds, minutes, hours.
    ///
    /// examples: `.seconds(10)`
    public var timeoutAfter: TimeAmount?

    // MARK: - Method
    /// Returns the httpBody as Data and with the proper encoding specified by
    /// the bodyEncoding property along with the content type. Returns nil when
    /// httpBody is nil.
    internal func encodeBody() throws -> (encodedData: Data?, contentType: String?) {
        if httpBody == nil {
            return (nil, nil)
        } else {
            return try bodyEncoding.encode(dict: httpBody!)
        }
    }
    
    // MARK: - Struct
    /// The response from a ``Swauthable/authenticatedRequest(for:numberOfRetries:)``.
    public struct Response {
        /// The data from the request.
        public let data: Data
        /// Retruns a [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) JSON instance
        /// from the request.
        public func json() throws -> JSON {
            return try data.toSwiftyJSON()
        }
    }

    // MARK: - Initializers
    /// Initializes a HTTPRequest object.
    ///
    /// See Also:
    /// - ``init(endpoint:withBody:bodyEncoding:)``
    ///
    /// - Parameter endpoint: The server endpoint URL to which the HTTP request will be sent.
    public init(endpoint: URL) {
        self.endpoint = endpoint
    }
    /// Initializes a HTTPRequest object, with a body.
    ///
    /// Calls ``init(endpoint:)``, and also initializes ``httpBody`` and ``bodyEncoding``.
    ///
    /// - Parameters:
    ///    - endpoint: The server endpoint URL to which the HTTP request will be sent.
    ///    - withBody: The body of the HTTP request.
    ///    - bodyEncoding: The ``RequestBodyEncoding``  type of the request body.
    public init(endpoint: URL,
                withBody: [String: Any],
                bodyEncoding: RequestBodyEncoding) {
        self.init(endpoint: endpoint)
        self.httpBody = withBody
        self.bodyEncoding = bodyEncoding
    }
}

// MARK: - Enumeration
/// Enumeration of possible encodings of a HTTP request body.
///
/// RequestBodyEncoding is ``HTTPRequest/bodyEncoding``'s type and is also used in some of
/// ``HTTPRequest``'s initializers.
public enum RequestBodyEncoding {
    /// application/x-www-form-urlencoded encoding
    case FORM
    /// application/JSON encoding
    case JSON

    /// Encodes a dictionary to data using the proper encoding method.
    internal func encode(dict: [String: Any]) throws -> (encodedData: Data, contentType: String) {
        switch self {
        case .FORM:
            return try (dict.httpForm(), "application/x-www-form-urlencoded")
        case .JSON:
            return try (dict.httpJSON(), "application/json")
        }
    }
}

// MARK: - Extension to Request
internal extension Request {
    /// Initializes a Request from an HTTPRequest.
    ///
    /// - Parameter from: A ``HTTPRequest``.
    init(from: HTTPRequest) throws {
        try self.init(url: from.queriedEndpoint, method: from.httpMethod)
        let (bodyData, contentType) = try from.encodeBody()
        if bodyData != nil {
            self.body = .data(bodyData!)
        }

        var headers = [String: String]()
        if contentType != nil {
            headers.merge(with: ["Content-Type": contentType!])
        }
        if from.additionalHTTPHeaders != nil {
            headers.merge(with: from.additionalHTTPHeaders!)
        }
        if headers.isEmpty == false {
            headers.forEach { (key, value) in
                self.headers.add(name: key, value: value)
            }
        }
    }
}
