import MacroTesting
import XCTest

final class URLMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: ["URL": URLMacro.self]) {
      super.invokeTest()
    }
  }

  func testExpansionWithMalformedURLEmitsError() {
    assertMacro {
      """
      let invalid = #URL("https://not a url.com")
      """
    } diagnostics: {
      """
      let invalid = #URL("https://not a url.com")
                    ┬────────────────────────────
                    ╰─ 🛑 malformed url: "https://not a url.com"
      """
    }
  }

  func testExpansionWithStringInterpolationEmitsError() {
    assertMacro {
      #"""
      #URL("https://\(domain)/api/path")
      """#
    } diagnostics: {
      #"""
      #URL("https://\(domain)/api/path")
      ┬─────────────────────────────────
      ╰─ 🛑 #URL requires a static string literal
      """#
    }
  }

  func testExpansionWithValidURL() {
    assertMacro {
      """
      let valid = #URL("https://swift.org/")
      """
    } expansion: {
      """
      let valid = URL(string: "https://swift.org/")!
      """
    }
  }
}
