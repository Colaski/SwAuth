# ``SwAuth``

Easily send OAuth 2.0 authorized HTTP requests with async/await in Swift.

## Overview


SwAuth provides an easy way to send OAuth 2.0 HTTP requests for Swift applications. It's built on SwiftNIO and utilizes Swift's new and intuitive async/await syntax. The library supports OAuth 2.0's: Authorization Code Flow with ``AuthorizationCodeFlow``, it's more secure extension, Proof Key for Code Exchange with ``PKCEAuthorizationFlow``, and the extension for when a browser interface is impractical, the Device Authorization Grant through the ``DeviceAuthorizationFlow``!


## Topics

### Essential

- <doc:Choosing-the-right-Authorization-Flow>
- ``Swauthable``

### The Authorization Flows

- ``AuthorizationCodeFlow``
- ``PKCEAuthorizationFlow``
- ``DeviceAuthorizationFlow``

### Request and Response

Use ``HTTPRequest`` to build a request, send the request with ``Swauthable/authenticatedRequest(for:numberOfRetries:)``, and get a ``HTTPRequest/Response``.

- ``HTTPRequest``
- ``Swauthable/authenticatedRequest(for:numberOfRetries:)``
- ``HTTPRequest/Response``

### Errors

- ``SwAuthError``
