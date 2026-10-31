import Testing
import Foundation
@testable import KayucoCore

@Test func losFixturesVienenEnElBundle() throws {
    let url = try #require(Bundle.module.url(forResource: "routing", withExtension: "md", subdirectory: "Fixtures"))
    #expect(try String(contentsOf: url, encoding: .utf8).contains("implementador-critico"))
}
