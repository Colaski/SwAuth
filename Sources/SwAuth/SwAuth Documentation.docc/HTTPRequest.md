# ``SwAuth/HTTPRequest``

HTTPRequest is very similar to URLSession's URLRequest. HTTPRequest represents an HTTP request.

## Topics

### Initialization

- ``init(endpoint:)``
- ``init(endpoint:withBody:bodyEncoding:)``

### Options

Options can be set for the request like this:

```swift
httpRequestInstance.endpointQueryItems = ["key": "value"]
```

- ``httpMethod``
- ``additionalHTTPHeaders``
- ``httpBody``
- ``bodyEncoding``
- ``endpointQueryItems``
- ``timeoutAfter``

### Initialized

- ``endpoint``
