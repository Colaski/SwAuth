# Contributing to SwAuth

Thanks for showing interest in contributing!

For fixes and improvements please fork this repository and issue a pull request.

You do not need a mac to contribute, all you need is Swift and [SwiftLint](https://github.com/realm/SwiftLint) (there is a SwiftLint VSCode extension). No linting rules are added or excluded, the default will do.

To have your changes merged make sure:

* There are no SwiftLint linting errors.
* SwAuth builds with your changes.
* Added code is documented, adhering somewhat to the style of the rest of the project. ([there are tons of examples in the code base](https://github.com/Colaski/SwAuth/blob/main/Sources/SwAuth/AuthorizationCodeFlow.swift))
* You have tested your changes through a test app or demo app or unit tests.

Besides whatever awesome idea you have here is a nice to have list:

* [ ] Include site-specific implementations, similar to in the [example app](https://github.com/Colaski/SwAuth/blob/main/SwAuthTestApp/SwAuthTestApp/Spotify.swift)
  * Perhaps Spotify, Google, Azure/Microsoft, Github, Reddit etc.
* [ ] Linux/Windows support
