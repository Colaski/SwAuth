//
// SwAuthError.swift
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

/// `SwAuthError` is the error type that is thrown by methods in this library.
///
/// Each error has a `localizedDescription`, which describes what the error is and why it may have
/// occurred. You can access that error by acessing the `localizedDescription` property.
///
/// For example, you can print a SwAuthError's description in a `catch` like so:
/// ```swift
/// catch {
///     print(error.localizedDescription)
/// }
/// ```
///
/// A more complete example using
/// ``Swauthable/authenticatedRequest(for:numberOfRetries:)``:
/// ```swift
/// do {
///     let getRequest = HTTPRequest(endpoint: URL(string: "https://domain.com/endpoint")!)
///
///     let response = try authorizationCodeFlowInstance.authenticatedRequest(for: getRequest)
///     print(response)
/// } catch {
///     print(error.localizedDescription)
/// }
/// ```
public enum SwAuthError: Error {
    // MARK: - Errors
    /// Gaining authorization failed and threw an error.
    case authorizationFailure(reason: AuthorizationErrorFailureReason)
    /// The underlying reason why an authorization error occurred.
    public enum AuthorizationErrorFailureReason: Error {
        /// The authorization callback URL is invalid.
        case authCallbackInvalid
        /// The instance's state does not match the one provided
        /// by the server in the callback URL. An incorrect state
        /// may be caused by atempted cross-site forgery.
        case stateIncorrect
        /// Callback URL contains an error.
        case authorizationError(with: String)
        /// The access token was invalid.
        case accessTokenInvalid
        /// The keychain does not contain a valid access token.
        case noAccessToken
        /// The refresh token must be a String.
        case refreshTokenInvalidType
        /// The keychain does not contain a valid refresh token.
        case noRefreshToken
        /// The response from the authorization endpoint is invalid or non-existant.
        case responseInvalid
        /// The authorization request was denied.
        case denied
        /// The device code has expired
        case deviceCodeExpired
        /// The response type must be URL from an ASWebAuthenticationSession.
        case responseNotURL
        /// The response type must be a ``DeviceAuthorizationFlow/DeviceAuthResponse``
        /// returned from a call to ``DeviceAuthorizationFlow/deviceFlowAuthorizationRequest()``.
        case responseNotDeviceFlowAuthResponse
    }
    /// JSON serialization failed with an error.
    case jsonSerializationFailure(error: Error)
    /// The URL query does not conform to RFC 1808.
    case queryParsingError
    /// An HTTP error occurred during a HTTP request with a response.
    case httpError(json: NSString)
    /// Parsing a dictionary to application/x-www-form-urlencoded data failed.
    case httpFormParsingFailure
    /// A SwiftyJSON error occurred.
    case swiftyJSONError(error: Error)
    /// A system error occurred.
    case systemError(error: Error)
    /// Polling for the Device Flow Authorization took too long.
    case pollingTooLong
}

// MARK: - Error Descriptions
extension SwAuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .authorizationFailure(reason):
            return reason.localizedDescription
        case let .jsonSerializationFailure(error):
            return "JSON serialization failed with an error: \(error.localizedDescription)"
        case .queryParsingError:
            return "The URL query does not conform to RFC 1808."
        case let .httpError(json):
            return "An HTTP error occurred during an HTTP request with a response: \(json)"
        case .httpFormParsingFailure:
            return "Parsing a dictionary to application/x-www-form-urlencoded data failed."
        case let .swiftyJSONError(error):
            return "A SwiftyJSON error ocurred: \(error.localizedDescription)"
        case let .systemError(error):
            return "A system error occurred: \(error.localizedDescription)"
        case .pollingTooLong:
            return "Polling for the Device Flow Authorization took too long (longer than 15 minutes)."
        }
    }
}

extension SwAuthError.AuthorizationErrorFailureReason {
    public var localizedDescription: String {
        switch self {
        case .authCallbackInvalid:
            return "The authorization callback URL is invalid."
        case .stateIncorrect:
            return """
                    The instance state does not match the one provided by the server in the callback URL.
                    An incorrect state may be caused by an atempted cross-site forgery.
                    """
        case let .authorizationError(with):
            return "Authorization failed with an error: \(with)"
        case .accessTokenInvalid:
            return "The access token given by the server was invalid."
        case .noAccessToken:
            return "Keychain does not contain a valid access token."
        case .refreshTokenInvalidType:
            return "The refresh token must be a String."
        case .noRefreshToken:
            return "Keychain does not contain a valid refresh token."
        case .responseInvalid:
            return "The response from the authorization endpoint is invalid or non-existant."
        case .denied:
            return "The authorization request was denied."
        case .deviceCodeExpired:
            return "The device code has expired, please try again."
        case .responseNotURL:
            return "The response type must be a URL from an ASWebAuthenticationSession."
        case .responseNotDeviceFlowAuthResponse:
            return """
                    The response type must be `DeviceAuthResponse` returned from a call
                    to `deviceFlowAuthorizationRequest()`."
                    """
        }
    }
}
