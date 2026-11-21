import Foundation
import XCTest
@testable import computer_use_mcp

final class HostModeTests: XCTestCase {
    func testOnlyNoArgumentAppLaunchStartsPersistentHost() {
        let appURL = URL(fileURLWithPath: "/Applications/Computer Use MCP.app")
        let cliURL = URL(fileURLWithPath: "/usr/local/bin/computer-use-mcp")

        XCTAssertEqual(argumentsWithoutLaunchServicesProcessNumber(["-psn_0_123"]), [])
        XCTAssertTrue(shouldRunHostWithoutArguments(arguments: [], bundleURL: appURL))
        XCTAssertFalse(shouldRunHostWithoutArguments(arguments: ["help"], bundleURL: appURL))
        XCTAssertFalse(shouldRunHostWithoutArguments(arguments: [], bundleURL: cliURL))
    }
}
