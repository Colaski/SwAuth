import XCTest

@testable import SwAuth
import AppKit

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
final class SwAuthTests: XCTestCase {
    let keychain = Keychain(service: "com.colaski.SwAuthTests")
        .label("SwAuthTests")
}



