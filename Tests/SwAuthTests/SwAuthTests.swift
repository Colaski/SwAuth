import XCTest

@testable import SwAuth
import AppKit

// Why are the tests empty? You may ask.
// Well, because it's much easier to test functionality in a test app than
// in traditional unit tests due to the need to deal with callback URLs.

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
final class SwAuthTests: XCTestCase {
    let keychain = Keychain(service: "com.colaski.SwAuthTests")
        .label("SwAuthTests")
}
