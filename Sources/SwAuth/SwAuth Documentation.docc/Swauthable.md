# ``SwAuth/Swauthable``

## Topics

### Default Implementations

Default implementations are methods or properties that every instance of an object conforming to the protocol will have, much like subclassing. (Every instance of ``AuthorizationCodeFlow``, ``PKCEAuthorizationFlow``,  and ``DeviceAuthorizationFlow`` will have these properties and methods).

- ``isAuthorized``
- ``authenticatedRequest(for:numberOfRetries:)``
