# Choosing which Authorization Flow to Use and When

Choosing the right Authorization Flow.

## Overview

SwAuth provides 3 different OAuth2.0 authorization flows to use: ``AuthorizationCodeFlow``, ``PKCEAuthorizationFlow``, and ``DeviceAuthorizationFlow``. Choosing which one to use and in what context can be difficult.

## AuthorizationCodeFlow

The ``AuthorizationCodeFlow`` is the most widely supported OAuth2.0 flow since it is the basic OAuth2.0 specification. It is used for devices that are not input-constrained (like on iOS, iPadOS, and macOS). However, it should be avoided if at all possible. As the warning I write in it's respective documentation states, "The OAuth 2.0 Authorization Code Flow is not secure for client side applications, it should only be used when ABSOLUTELY NECESSARY." The reason for this is that in a native app the client secret must be embedded in the source somehow which you are compiling and distributing. Strings can be pretty easily extracted from binaries. Having the client secret would allow an attacker to exchange an intercepted Authorization Code for a token using the client secret, giving the attacker access to your user's account 😳.

Thus, if you are using SwAuth to send authorized requests to your server please implement [RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636). I'm sure there is a library or framework that implements it for whatever language you are using server-side ([here's one for Node.js](https://github.com/panva/node-oidc-provider)). If it is not your server, contact the owner and ask about implementing PKCE. But, if all else fails you may be forced to use the ``AuthorizationCodeFlow`` 😞, in which case I'd recommend using some sort of obfuscation technique for the client secret (at minimum don't just have a client secret as a plain string). Obfuscation isn't very secure but it's better than nothing.

## PKCEAuthorizationFlow

Much like the AuthorizationCodeFlow, the ``PKCEAuthorizationFlow`` is used for devices that are not input-constrained (like iOS, iPadOS, and macOS). Unlike the AuthorizationCodeFlow, the PKCE Authorization Code Flow is safe for use in native applications (the spec was created for such purpose). No need to provide the client secret, with PKCE (Proof Key for Code Exchange) an attacker in possesion of an intercepted Authorization Code can't exchange it for a token unless they have the on-device-cryptographically-generated code verifer 😮‍💨. 

The only downside is that the Proof Key for Code Exchange extension to the OAuth 2.0 Authorization Code Grant needs to be supported by the web API you are trying to send requests to. If you own the server, great! implement [RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636) and/or find a server-side framework or library that implements it ([again, here's one for Node.js](https://github.com/panva/node-oidc-provider)). Otherwise, ask the owner to implement it.

## DeviceAuthorizationFlow

The ``DeviceAuthorizationFlow`` is for use on devices that are input-constrained (like watchOS and tvOS). If the web API you are trying to send requests to does not support the  Device Authorization Grant ask the owner, assuming you don't own the server in which case stop being lazy.
