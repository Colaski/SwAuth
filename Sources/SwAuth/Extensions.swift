//
// Extensions.swift
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

// MARK: - Dictionary+merge, httpForm, httpJSON
internal extension Dictionary {
    /// Merges the dictionary with another.
    ///
    /// - Parameter with: The dictionary to be merged.
    mutating func merge(with: Dictionary) {
        with.forEach { self[$0] = $1 }
    }

    /// Returns application/x-www-form-urlencoded data.
    ///
    /// - Throws: ``SwAuthError/httpFormParsingFailure``
    func httpForm() throws -> Data {
        let data = self.map { "\($0)=\($1)" }
            .joined(separator: "&")
            .data(using: String.Encoding.utf8)
        guard data != nil else { throw SwAuthError.httpFormParsingFailure }
        return data!
    }

    /// Returns JSON data.
    ///
    /// - Throws: ``SwAuthError/jsonSerializationFailure(error:)``
    func httpJSON() throws -> Data {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: [])
            return data
        } catch {
            throw SwAuthError.jsonSerializationFailure(error: error)
        }
    }
}

// MARK: - Data+jsonToDict, jsonString
internal extension Data {
    /// JSON data as an NSString
    var jsonString: NSString? { // NSString is printed all nice while mormal String is not :(.
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return string
    }

    /// Returns a SwiftyJSON object from JSON formatted data.
    ///
    /// - Throws: ``SwAuthError/swiftyJSONError(error:)``
    func toSwiftyJSON() throws -> JSON {
        do {
           return try JSON(data: self)
        } catch {
            throw SwAuthError.swiftyJSONError(error: error)
        }
    }
}

// MARK: - URL+addQueryItems, addFragment, queryAsDictionary
internal extension URL {
    /// Returns a URL appended with query items from a dictionary. If query items couldn't be appended,
    /// returns the original URL.
    ///
    /// The dictionary ["q":"hello"] as the function paramter would return the URL:
    ///
    ///     www.domain.com/search
    /// as
    ///
    ///     www.domain.com/search?q=hello
    ///
    /// - Parameter items: The query items represented by a dictionary.
    func addQueryItems(_ items: [String: String]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.queryItems = items.map { (key, value) in
            return URLQueryItem(name: key, value: value)
        }
        return components?.url ?? self
    }

    /// Returns a dictionary derived from the query components of the URL, assuming RFC 1808 compliance.
    ///
    /// - Throws: ``SwAuthError/queryParsingError``
    func queryAsDictionary() throws -> [String: String] {
        guard let query = self.query else { throw SwAuthError.queryParsingError }

        return query.components(separatedBy: "&").map({
            $0.components(separatedBy: "=")
        }).reduce(into: [String: String]()) { dict, pair in
            if pair.count == 2 {
                dict[pair[0]] = pair[1]
            }
        }
    }
}

// MARK: - String+random, swiftyJSON
internal extension String {
    /// Returns a random alphanumeric string.
    ///
    /// As far as I'm aware, the randomElement method is random enough.
    ///
    /// - Parameter ofLength: The length of the returned string.
    static func random(ofLength: UInt8) -> String {
        // from: https://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<ofLength).map { _ in chars.randomElement()! })
    }
}
