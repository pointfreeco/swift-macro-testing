import MacroTesting
import XCTest

final class WarningMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(macros: ["myWarning": WarningMacro.self]) {
      super.invokeTest()
    }
  }

  func testWarning() {
    assertMacro {
      #"""
      #myWarning("remember to pass a string literal here")
      """#
    } diagnostics: {
      """
      #myWarning("remember to pass a string literal here")
      ┬───────────────────────────────────────────────────
      ╰─ ⚠️ remember to pass a string literal here
      """
    } expansion: {
      """
      ()
      """
    }
  }

  func testNonLiteral() {
    assertMacro {
      """
      let text = "oops"
      #myWarning(text)
      """
    } diagnostics: {
      """
      let text = "oops"
      #myWarning(text)
      ┬───────────────
      ╰─ 🛑 #myWarning macro requires a string literal
      """
    }
  }
}
