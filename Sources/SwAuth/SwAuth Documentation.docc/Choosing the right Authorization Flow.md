# Choosing the Right Authorization Flow

SwAuth provides 3 different OAuth 2.0 authorization flows to use: ``AuthorizationCodeFlow``, ``PKCEAuthorizationFlow``, and ``DeviceAuthorizationFlow``. Choosing which one to use and in what context can be difficult.

## AuthorizationCodeFlow

The ``AuthorizationCodeFlow`` is the most widely supported OAuth 2.0 flow since it is the basic OAuth 2.0 specification. It is used for devices that are not input-constrained (like on iOS, iPadOS, and macOS). However, it should be avoided if at all possible. As the warning I wrote in it's respective documentation states, "The OAuth 2.0 Authorization Code Flow is not secure for native applications, it should only be used when ABSOLUTELY NECESSARY." The reason for this is that in a native app the client secret is included in the source, which you are compiling and distributing. Strings can be pretty easily extracted from compiled binaries, giving someone access to your client secret. Knowing the client secret would allow an attacker to exchange an intercepted authorization code for a token, giving the attacker access to your user's account 😳.

Thus, if you are using SwAuth to send authorized requests to your server please implement [RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636). I'm sure there is a library or framework that implements it for whatever language you are using server-side ([here's one for Node.js](https://github.com/panva/node-oidc-provider)). If it is not your server, contact the owner and ask about implementing PKCE. If all else fails you may be forced to use the ``AuthorizationCodeFlow``, in which case I'd recommend using some sort of obfuscation and encryption technique for the client secret (at a minimum don't just have a client secret as a plain string). Obfuscation isn't very secure but it's better than nothing.

## PKCEAuthorizationFlow

Much like the AuthorizationCodeFlow, the ``PKCEAuthorizationFlow`` is used for devices that are not input-constrained (like iOS, iPadOS, and macOS). Unlike the AuthorizationCodeFlow, the PKCE Authorization Code Flow is safe for use in native applications (the spec was created for such purpose). No need to provide the client secret, with PKCE (Proof Key for Code Exchange) an attacker in possession of an intercepted Authorization Code can't exchange it for a token unless they have the on-device-cryptographically-generated code verifier.

The downside is that the Proof Key for Code Exchange extension to the OAuth 2.0 Authorization Code Grant needs to be supported by the Web API you are trying to send requests to. If you own the server, great! implement [RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636) and/or find a server-side framework or library that implements it ([again, here's one for Node.js](https://github.com/panva/node-oidc-provider)). Otherwise, ask the owner to implement it.

## DeviceAuthorizationFlow

The ``DeviceAuthorizationFlow`` is used for use on devices that are input-constrained (like watchOS and tvOS). If the Web API you are trying to send requests to does not support the  Device Authorization Grant ask the owner. If you own the server implement it or use a server-side library/framework that supports it.
