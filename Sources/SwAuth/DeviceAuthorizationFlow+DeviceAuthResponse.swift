//
// DeviceAuthorizationFlow+DeviceAuthResponse.swift
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
import EFQRCode
import CoreGraphics
import enum NIOHTTP1.HTTPMethod

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension DeviceAuthorizationFlow {
    /**
     The response returned from the ``deviceFlowAuthorizationRequest()`` method.
     Used as the parameter in the ``authorizationResponseHandler(for:)`` method.
     
     The ``verificationURI`` and ``userCode`` properties  should be displayed or otherwise
     communicated to the end user with instructions to visit the URI (or scan the ``qrCode``) on a
     secondary device (for example a mobile phone) and enter the user code.
     
     Example display from RFC 8628:
     
         +-----------------------------------------------+
         |                                               |
         |  Using a browser on another device, visit:    |
         |  https://example.com/device                   |
         |                                               |
         |  And enter the code:                          |
         |  WDJB-MJHT                                    |
         |                                               |
         +-----------------------------------------------+
     
     - Important: As per RFC 8628, the ``qrCode`` should be displayed **in addition**  to the
     ``verificationURI`` and ``userCode``. For accessibility reasons, the QR code does not replace
     displaying the ``verificationURI`` and ``userCode`` directly. See [RFC 8628 Section
     -3.3 and 3.3.1](https://datatracker.ietf.org/doc/html/rfc8628#section-3.3)
     for more information.
     
     Example display from RFC 8628:
     
         |-------------------------------------------------|
         |                                                 |
         |  Scan the QR code or, using     |------------|  |
         |  a browser on another device,   |[_]..  . [_]|  |
         |  visit:                         | .  ..   . .|  |
         |  https://example.com/device     | . .  . ....|  |
         |                                 |.   . . .   |  |
         |  And enter the code:            |[_]. ... .  |  |
         |  WDJB-MJHT                      |------------|  |
         |                                                 |
         |-------------------------------------------------|
     */
    public struct DeviceAuthResponse {
        // MARK: - Properties
        /// The device code.
        internal let deviceCode: String
        /// The user code that the end user must type-in after following the ``verificationURI``.
        ///
        /// The user code should be displayed or otherwise communicated to the end user with
        /// instructions to visit the ``verificationURI`` on a secondary device (for example a mobile
        /// phone) .
        public let userCode: String
        /// The verification URI should be displayed or otherwise communicated to the end user with instructions
        /// to follow it and type-in the ``userCode`` using a secondary device (for example a mobile
        /// phone) .
        public let verificationURI: String
        /**
         The server may respond with a complete verification URI in addition to a verification URI (the verification
         URI combined with the user code). Following the complete verification URI allows the user to not have to type-in
         the user code. Is nil if one was not provided.
         
         - Important: As per RFC 8628, do not display the ``completeVerificationURI`` directly to the
         user because of its increased complexity, instead display a ``qrCode``. See [RFC 8628 Section
         -3.3 and 3.3.1](https://datatracker.ietf.org/doc/html/rfc8628#section-3.3)
         for more information.
         */
        public let completeVerificationURI: String?
        /**
         A QR code of the ``verificationURI`` or ``completeVerificationURI`` as a Core Graphics CGImage.
         If generating the QR code fails for some reason, is nil.
         
         Converting the CGImage:
         ```swift
         if let cgImage = deviceFlowAuthorizationResponse.qrCode { // Unwrap the optional.
            // For UIKit targets
            let uiImage = UIImage(CGImage: cgImage) // UIKit UIImage
            let image = Image(uiImage: uiImage) // SwiftUI Image from UIImage
         
            // For AppKit targets
            // size: NSZeroSize makes the NSImage the same size as the CGImage.
            let nsImage = NSImage(cgImage: cgImage, size: NSZeroSize) // AppKit NSImage
            let image = Image(nsImage: nsImage) // SwiftUI Image from NSImage
         }
         ```
         
         The server may respond with a complete verification URI in addition to a verification URI.
         If a ``completeVerificationURI`` is provided, the QR code will display it, allowing a user to not
         have to type-in the user code manually. Otherwise, the QR code will display the ``verificationURI``.
         
         - Important: The QR code should be displayed **in addition**  to the ``verificationURI``
         and ``userCode``. For accessibility reasons, the QR code does not replace displaying the
         ``verificationURI`` directly.
         
         Example display from RFC 8628:
         
             |-------------------------------------------------|
             |                                                 |
             |  Scan the QR code or, using     |------------|  |
             |  a browser on another device,   |[_]..  . [_]|  |
             |  visit:                         | .  ..   . .|  |
             |  https://example.com/device     | . .  . ....|  |
             |                                 |.   . . .   |  |
             |  And enter the code:            |[_]. ... .  |  |
             |  WDJB-MJHT                      |------------|  |
             |                                                 |
             |-------------------------------------------------|
         */
        public var qrCode: CGImage? {
            return verificationQRCode()
        }
        /// How long the codes are good for (seconds)
        public let expiresIn: Double
        /// The time the request was made (UTC time zone).
        public let requestMade = Date()
        /// Interval for polling token requests in seconds. Defaults to 5 if not provided by the server.
        internal let interval: UInt32
        /// True when the codes have expired.
        public var isExpired: Bool {
            // If the time from 5 seconds from now is less than the time at which
            // the code expires, false. Otherwise, true
            return Date() + 5 < requestMade + expiresIn ? false : true
        }
        /// The time the codes expire at (UTC time zone).
        public var expiresAt: Date {
            return requestMade + expiresIn
        }

        // MARK: - Method
        /// Generates a CGImage QR code from a verification URL.
        internal func verificationQRCode() -> CGImage? {
            let string = completeVerificationURI != nil ? completeVerificationURI! : verificationURI
            return EFQRCode.generate(for: string)
        }

        // MARK: - Inits
        private init(deviceCode: String,
                     userCode: String,
                     verificationURI: String,
                     completeVerificationURI: String?,
                     expiresIn: Double,
                     interval: UInt32) {
            self.deviceCode = deviceCode
            self.userCode = userCode
            self.verificationURI = verificationURI
            self.completeVerificationURI = completeVerificationURI
            self.expiresIn = expiresIn
            self.interval = interval
        }
        /// Initializes an instance from a SwiftyJSON instance.
        ///
        /// - Parameter fromJSON: A SwiftyJSON JSON instance.
        init(fromJSON: JSON) throws {
            // Some servers return "verification_url" as the key instead of
            // "verification_uri" that is specified in the standard.
            // Looking at you Google.
            var verificationURx: String? {
                if let uri = fromJSON["verification_uri"].string {
                    return uri
                } else if let url = fromJSON["verification_url"].string {
                    return url
                } else {
                    return nil
                }
            }
            guard let deviceCode = fromJSON["device_code"].string,
                  let userCode = fromJSON["user_code"].string,
                  verificationURx != nil,
                  let expiresIn = fromJSON["expires_in"].double
            else {
                throw SwAuthError.authorizationFailure(reason: .responseInvalid)
            }
            let verifURIComplete = fromJSON["verification_uri_complete"].string
            let interval = fromJSON["interval"].uInt32 ?? 5
            
            self.init(deviceCode: deviceCode,
                      userCode: userCode,
                      verificationURI: verificationURx!,
                      completeVerificationURI: verifURIComplete,
                      expiresIn: expiresIn,
                      interval: interval)
        }
    }
}
