import MacroTesting
import XCTest

final class AssertMacroTests: BaseTestCase {
  #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS) || os(watchOS)
    func testMacrosRequired() {
      XCTExpectFailure {
        assertMacro {
          """
          #forgotToConfigure()
          """
        }
      } issueMatcher: {
        $0.compactDescription == """
          failed - No macros configured for this assertion. Pass a mapping to this function, e.g.:

              assertMacro(["stringify": StringifyMacro.self]) { … }

          Or wrap your assertion using 'withMacroTesting', e.g. in 'invokeTest':

              class StringifyMacroTests: XCTestCase {
                override func invokeTest() {
                  withMacroTesting(macros: ["stringify": StringifyMacro.self]) {
                    super.invokeTest()
                  }
                }
                …
              }
          """
      }
    }
  #endif
}
